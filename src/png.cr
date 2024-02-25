require "compress/zlib"

require "./png/inflater"
require "./png/header"
require "./png/error"
require "./png/scanline"
require "./png/parser"
require "./png/chunk"
require "./png/canvas"

module PNG
  # Only logs messages if built with `-Dpng-PNG.debug`
  macro debug(args)
    {% if flag?(:"png-debug") %}
      if typeof({{args}}) == String
        STDOUT.puts({{args}})
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
    png_magic = Bytes.new(8)
    io.read_fully(png_magic)
    raise Error.new("PNG magic mismatch: #{png_magic}") unless png_magic == MAGIC

    header = uninitialized Header

    Chunk.read(io) do |chunk_type, io, byte_size|
      raise Error.new("Wrong chunk type: #{chunk_type} (not IHDR)") unless chunk_type == "IHDR"
      header = Header.parse(io)
      PNG.debug header
    end

    inflater = Inflater.new
    parser = Parser.new(header)
    canvas = Canvas.new(header)
    previous = Scanline.new(header, FilterMethod::None, Bytes.new(parser.scanline_size))
    row_buffer = Bytes.new(parser.scanline_size + 1)
    pixel_size = header.width * header.height
    pixel = 0

    loop do
      chunk_type = Chunk.read(io) do |chunk_type, io, byte_size|
        case chunk_type
        when "PLTE"
          palette = Bytes.new(byte_size)
          io.read_fully(palette)
          canvas.palette = palette
        when "IDAT"
          while byte = io.read_byte
            inflater.inhale(byte)

            while inflater.bytes_available >= row_buffer.size
              inflater.read(row_buffer)
              scanline = Scanline.new(header, FilterMethod.new(row_buffer[0]), row_buffer[1..])
              scanline.unfilter(previous)

              pixel += parser.row_pixels
              y = parser.y

              parser.row_pixels.times do |n|
                x = parser.x(n)
                bytes = scanline.pixel(n)
                canvas[x, y] = bytes
              end

              break if pixel >= pixel_size

              if parser.next
                # print_canvas(canvas)
                previous.data = Bytes.new(parser.scanline_size)
                row_buffer = Bytes.new(parser.scanline_size + 1)
              else
                previous.data.copy_from(scanline.data)
              end
            end
          end
        else
          PNG.debug "Ignoring #{chunk_type} chunk"
        end
      end

      break if chunk_type == "IEND"
    end

    canvas
  end

  def self.write(path : String, canvas : Canvas)
    File.open(path, "w") do |file|
      PNG.write(file, canvas)
    end
  end

  def self.write(io : IO, canvas : Canvas)
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
          index = 0
          parser = Parser.new(canvas.header)
          total_pixels = canvas.width * canvas.height
          until index >= total_pixels
            row_pixels = parser.row_pixels
            bpr = canvas.header.bytes_per_row(row_pixels)

            scanline = Scanline.new(canvas.header, FilterMethod::None, Bytes.new(bpr))

            y = parser.y

            row_pixels.times do |n|
              x = parser.x(n)
              scanline.set_pixel(n, canvas[x, y])
            end

            index += row_pixels

            deflate.write_byte(scanline.filter.value)
            scanline.filter(previous) do |byte|
              deflate.write_byte(byte)
            end
            previous = scanline

            if parser.next
              previous = nil
            end
          end
        end
      end
    end

    Chunk.write("IEND", io, Bytes[])
  end
end
