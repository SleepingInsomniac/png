require "compress/zlib"

require "./png/error"
require "./png/chunk"
require "./png/header"
require "./png/parsers/parse_IHDR"
require "./png/parsers/parse_PLTE"
require "./png/parsers/parse_IDAT"

module PNG
  # Only logs messages if built with `-Dpng-PNG.debug`
  macro debug(args)
    {% if flag?(:"png-debug") %}
      if typeof({{args}}) == String
        puts({{args}})
      else
        pp({{args}})
      end
    {% end %}
  end

  VERSION = {{`shards version`.stringify.chomp}}

  # "\x89PNG\r\n\x1a\n"
  MAGIC = Bytes[137, 80, 78, 71, 13, 10, 26, 10]

  def self.read(path : String)
    PNG.debug "Reading path: #{path}"
    File.open(path, "rb") { |io| self.read(io) }
  end

  def self.read(io : IO)
    finished = false

    header : Header? = nil
    palette : Slice(UInt8)? = nil
    canvas : Canvas? = nil
    idat_parser : ParserIDAT? = nil

    png_magic = Bytes.new(8)
    io.read_fully(png_magic)
    raise Error.new("PNG magic mismatch: #{png_magic}") unless png_magic == MAGIC

    loop do
      Chunk.read(io) do |io, byte_size, chunk_type|
        case chunk_type
        when "IHDR"
          header = PNG.parse_IHDR(io)
          PNG.debug header
          canvas = Canvas.new(header)
          PNG.debug "Expecting #{header.data_size} byte canvas"
          idat_parser = ParserIDAT.new(canvas)
        when "PLTE"
          raise Error.new("PLTE read before header") if header.nil?
          palette = PNG.parse_PLTE(io, byte_size)
          canvas.not_nil!.palette = palette
        when "IDAT"
          raise Error.new("IDAT read before header") if header.nil?
          idat_parser.not_nil!.parse(io, byte_size)
        when "IEND" then finished = true
        else
          PNG.debug "(ignored chunk)"
        end
      end

      break if finished
    end

    canvas.not_nil!
  end

  def self.write(canvas : Canvas, path : String)
    File.open(path, "w") do |file|
      PNG.write(canvas, file)
    end
  end

  def self.write(canvas : Canvas, io : IO)
    io.write(MAGIC)
    canvas.header.write(io)

    if canvas.header.color_type.indexed?
      if palette = canvas.palette
        Chunk.write("PLTE", io, palette)
      else
        raise Error.new("Missing palette for Indexed color type")
      end
    end

    Chunk.write("IDAT", io) do |data|
      previous : Scanline? = nil

      Compress::Zlib::Writer.open(data) do |deflate|
        case canvas.header.interlacing
        when .none?
          0u32.upto(canvas.height - 1) do |y|
            # TODO: Choose the smallest filter method
            bpr = canvas.bytes_per_row
            offset = y * bpr
            scanline = Scanline.new(canvas.header, FilterMethod::None, canvas.data[offset...(offset + bpr)])

            deflate.write_byte(scanline.filter.value)
            scanline.filter(previous) do |byte|
              deflate.write_byte(byte)
            end
            previous = scanline
          end
        else
          # TODO: Write Adam7 interlacing
          raise Error.new("Can't write #{canvas.header.interlacing}")
        end
      end
    end

    Chunk.write("IEND", io, Bytes[])
  end
end
