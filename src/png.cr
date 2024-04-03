require "compress/zlib"

require "./png/inflater"
require "./png/header"
require "./png/error"
require "./png/scanline"
require "./png/parser"
require "./png/chunk"
require "./png/canvas"
require "./png/heuristic"
require "./png/packed_data"

module PNG
  # Only logs messages if built with `-Dpng-debug`
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

  # MAGIC is the first 8 bytes of a PNG file: "\x89PNG\r\n\x1a\n"
  MAGIC = Bytes[137, 80, 78, 71, 13, 10, 26, 10]

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # Reads a png stream returns a *PNG::Canvas*
  #
  # ```
  # canvas = PNG.read("examples/gradient.png")
  # canvas.header.color_type # => PNG::ColorType::RGB
  # canvas[0, 0]             # => Bytes[0, 255, 0]
  # ```
  #
  def self.read(path : String) : Canvas
    PNG.debug "Reading path: #{path}"
    File.open(path, "rb") { |io| self.read(io) }
  end

  # :ditto:
  def self.read(io : IO) : Canvas
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
          canvas.palette = Palette.new(Bytes.new(byte_size))
          io.read_fully(canvas.palette.not_nil!.data)
        when "tRNS"
          canvas.transparency = Bytes.new(byte_size)
          io.read_fully(canvas.transparency.not_nil!)
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
                previous.data = Bytes.new(parser.scanline_size)
                row_buffer = Bytes.new(parser.scanline_size + 1)
              else
                previous.data.copy_from(scanline.data)
              end
            end
          end
        when "pHYs"
          canvas.pixel_size = PixelSize.parse(io)
          PNG.debug "pHYs: #{canvas.pixel_size}"
        when "bKGD"
          bg_color = Bytes.new(header.bytes_per_pixel)
          io.read_fully(bg_color)
          canvas.bg_color = bg_color
          PNG.debug "bKGD: #{bg_color}"
        when "tIME"
          year = io.read_bytes(UInt16, IO::ByteFormat::BigEndian).to_i32
          month = io.read_bytes(UInt8).to_i32
          day = io.read_bytes(UInt8).to_i32
          hour = io.read_bytes(UInt8).to_i32
          minute = io.read_bytes(UInt8).to_i32
          second = io.read_bytes(UInt8).to_i32
          canvas.last_modified = Time.utc(year, month, day, hour, minute, second)
          PNG.debug "tIME: #{canvas.last_modified}"
        when "gAMA"
          canvas.gama = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
          PNG.debug "gAMA: #{canvas.gama}"
        when "IEND"
        else
          PNG.debug "Ignoring #{chunk_type} chunk"
        end
      end

      break if chunk_type == "IEND"
    end

    canvas
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # Write a *canvas* to a .png file given a *path*
  #
  # ```
  # canvas = PNG::Canvas.new(255, 255)
  # 0.upto(canvas.height - 1) do |y|
  #   0.upto(canvas.width - 1) do |x|
  #     canvas[x, y] = Bytes[x, 255, y]
  #   end
  # end
  #
  # PNG.write("examples/gradient.png", canvas)
  # ```
  def self.write(path : String, canvas : Canvas, &heuristic : (Scanline?, Scanline) -> Scanline)
    File.open(path, "w") do |file|
      PNG.write(file, canvas, &heuristic)
    end
  end

  # Write a *canvas* to a given *io* in png format.
  def self.write(io : IO, canvas : Canvas, &heuristic : (Scanline?, Scanline) -> Scanline)
    io.write(MAGIC)
    canvas.header.write(io)

    if last_modified = canvas.last_modified
      Chunk.write("tIME", io) do |data|
        year = data.write_bytes(last_modified.year.to_u16, IO::ByteFormat::BigEndian)
        month = data.write_byte(last_modified.month.to_u8)
        day = data.write_byte(last_modified.day.to_u8)
        hour = data.write_byte(last_modified.hour.to_u8)
        minute = data.write_byte(last_modified.minute.to_u8)
        second = data.write_byte(last_modified.second.to_u8)
      end
    end

    if pixel_size = canvas.pixel_size
      Chunk.write("pHYs", io) { |data| pixel_size.write(data) }
    end

    if gama = canvas.gama
      Chunk.write("gAMA", io) { |data| data.write_bytes(gama, IO::ByteFormat::BigEndian) }
    end

    if canvas.header.color_type.indexed?
      if palette = canvas.palette
        Chunk.write("PLTE", io, palette.data)
      else
        raise Error.new("Missing palette for Indexed color type")
      end
    end

    unless canvas.header.color_type.alpha?
      if transparency = canvas.transparency
        Chunk.write("tRNS", io, transparency)
      end
    end

    if bg_color = canvas.bg_color
      Chunk.write("bKGD", io, bg_color)
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
            scanline = yield previous, scanline

            deflate.write_byte(scanline.filter.value)
            scanline.filter(previous) { |byte| deflate.write_byte(byte) }
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

            scanline = yield previous, scanline

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

  def self.write(path : String, canvas : Canvas)
    write(path, canvas, &Heuristic::NONE)
  end

  def self.write(io : IO, canvas : Canvas)
    write(io, canvas, &Heuristic::NONE)
  end
end
