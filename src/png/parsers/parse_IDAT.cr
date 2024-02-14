require "../adam_7"
require "../canvas"
require "../header"
require "../scanline"
require "../inflate_stream"

module PNG
  class ParserIDAT
    private class Inflater < Compress::Deflate::Reader
      setter io : IO
    end

    @pos = 0u32
    @canvas : Canvas
    @previous_scanline : Scanline? = nil
    @stream = InflateStream.new
    @pass_index = 0
    @deflate_header_bytes = 0u8
    @buffer = IO::Memory.new
    @row_index = 0

    delegate :header, :width, :height, to: @canvas

    def initialize(@canvas)
    end

    def parse(io : IO, byte_size)
      # Discard the zlib header, chunk's crc32 is sufficient
      while @deflate_header_bytes < 2 && (byte = io.read_byte)
        @deflate_header_bytes += 1
      end

      return if @deflate_header_bytes < 2

      IO.copy(io, @stream, byte_size)

      case header.interlacing
      when Interlacing::None  then parse_none
      when Interlacing::Adam7 then parse_adam7
      else
        raise Error.new("Unknown interlacing method: #{header.interlacing}")
      end
    end

    # Reads upto *bytes* uncompressed data from the compressed *@stream* into the working *@buffer*
    # Ends early if there aren't bytes available in the compressed stream.
    private def slurp(bytes)
      slurped = 0
      while @buffer.size < bytes && (byte = @stream.read_byte)
        slurped += 1
        @buffer.write_byte(byte)
      end
      @buffer.size
    end

    private def parse_none
      row_bytes = header.bytes_per_row(header.width)

      loop do
        break if @pos >= @canvas.data.size

        slurp(row_bytes + 1)
        break if @buffer.size < (row_bytes + 1)
        @buffer.rewind

        filter_byte = @buffer.read_bytes(UInt8)
        filter = FilterMethod.new(filter_byte)
        PNG.debug "row: #{filter} (#{@pos}-#{@pos + row_bytes - 1})"
        scanline = Scanline.new(header, filter, @canvas.data[@pos...(@pos + row_bytes)])
        @pos += row_bytes
        @buffer.read_fully(scanline.data)
        @buffer.clear
        scanline.unfilter(@previous_scanline)
        @previous_scanline = scanline
      end
    end

    private def parse_adam7
      reached_end = false

      loop do
        break if @pos >= @canvas.data.size

        pass = A7_PASSES[@pass_index]
        # PNG.debug "Pass #{@pass_index}: #{pass} #{row_pixels}x#{pass_rows}"

        if pass[:start_x] >= width || pass[:start_y] >= height
          @pass_index += 1
          next
        end

        row_pixels = ((width - pass[:start_x]) / pass[:each_x]).ceil.to_u32
        pass_rows = ((height - pass[:start_y]) + (pass[:each_y] - 1)) // pass[:each_y]
        row_bytes = header.bytes_per_row(row_pixels)

        slurp(row_bytes + 1)
        break if @buffer.size < (row_bytes + 1)
        @buffer.rewind

        filter_byte = @buffer.read_bytes(UInt8)
        filter = FilterMethod.new(filter_byte)

        end_index = @pos + row_bytes
        end_index = @canvas.data.size.to_u32 if end_index > @canvas.data.size

        PNG.debug "row #{(@row_index + 1).to_s.rjust(2)}/#{pass_rows.to_s.ljust(2)}: #{filter} (#{@pos}-#{end_index - 1}) #{end_index - @pos} bytes"

        # scanline = Scanline.new(header, filter, @canvas.data[@pos...(@pos + row_bytes)])
        scanline = Scanline.new(header, filter, Bytes.new(row_bytes))
        @buffer.read_fully(scanline.data)
        @buffer.clear

        scanline.unfilter(@previous_scanline)

        y = pass[:start_y] + (@row_index * pass[:each_y])
        row_pixels.times do |n|
          x = pass[:start_x] + (n * pass[:each_x])
          @canvas[x, y] = scanline.pixel(n)
        end

        @previous_scanline = scanline
        @pos = end_index

        if @pos >= @canvas.data.size
          reached_end = true
          break
        end

        @row_index += 1
        if @row_index >= pass_rows
          @row_index = 0
          @pass_index += 1
        end

        break if reached_end || @pass_index > A7_PASSES.size
      end
    end
  end
end
