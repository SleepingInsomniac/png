require "compress/zlib"
require "./scanline"

module PNG
  class DataChunk < Chunk
    TYPE = "IDAT"
    @chunk_type = TYPE

    A7_PASSES = [
      {start_x: 0, start_y: 0, each_x: 8, each_y: 8}, # 1
      {start_x: 4, start_y: 0, each_x: 8, each_y: 8}, # 2
      {start_x: 0, start_y: 4, each_x: 4, each_y: 8}, # 3
      {start_x: 2, start_y: 0, each_x: 4, each_y: 4}, # 4
      {start_x: 0, start_y: 2, each_x: 2, each_y: 4}, # 5
      {start_x: 1, start_y: 0, each_x: 2, each_y: 2}, # 6
      {start_x: 0, start_y: 1, each_x: 1, each_y: 2}, # 7
    ]

    # Calculate a Range that represents the index into the data : Bytes
    #
    def self.row_range(row_index, bytes_per_row)
      start_index = row_index * bytes_per_row
      end_index = start_index + bytes_per_row
      start_index...end_index
    end

    # Go through each scanline of data and remove the filtering depending on the filter
    # used to encode that specific line.
    #
    def self.parse(filtered : IO, width : Int, height : Int, options : Options)
      bits_per_pixel = options.bits_per_pixel
      bytes_per_pixel = (bits_per_pixel // 8).clamp(1..)
      # output_bytes = ((width * bits_per_pixel) / 8).ceil.to_i32 * height

      data = Bytes.new((width * bytes_per_pixel) * height)
      previous_row : Bytes? = nil

      debug "Decoding: #{width}x#{height} - bytes per pixel: #{bytes_per_pixel}"

      bytes_read = 0
      start_index = 0

      passes = options.interlacing.adam7? ? A7_PASSES : [{start_x: 0, start_y: 0, each_x: 1, each_y: 1}]

      passes.each_with_index do |pass, i|
        debug "\nPass ##{i}: #{pass}"
        row_pixels = ((width - pass[:start_x]) / pass[:each_x]).ceil.to_i32
        pass_rows = ((height - pass[:start_y]) + (pass[:each_y] - 1)) // pass[:each_y]

        debug "#{row_pixels}x#{pass_rows}"
        debug "--------------"

        pass_rows.times do |row_index|
          row_width_bytes = ((bits_per_pixel * row_pixels) / 8).ceil.to_i32
          filter = FilterMethod.new(filtered.read_bytes(UInt8))

          end_index = start_index + row_width_bytes
          row = data[start_index...end_index]

          filtered.read_fully(row)

          debug "#{row_index.to_s.rjust(2)}: #{filter.to_s.rjust(8)}  #{row.map { |r| r.to_s(16).rjust(2, '0') }.join(' ')}"
          scanline = Scanline.new(row, bytes_per_pixel)

          case filter
          when FilterMethod::None
          when FilterMethod::Sub     then scanline.unsub!
          when FilterMethod::Up      then scanline.unup!(previous_row)
          when FilterMethod::Average then scanline.unaverage!(previous_row)
          when FilterMethod::Paeth   then scanline.unpaeth!(previous_row)
          else                            raise "Unsupported filter method: #{filter}"
          end

          previous_row = row
          start_index = end_index
        end
      end

      new(data, width, bytes_per_pixel)
    end

    getter data : Bytes
    @width : UInt32
    getter bits_per_pixel : Int32
    @compression_method = Compression::Deflate
    @deflate_speed = Compress::Deflate::BEST_SPEED

    def initialize(
      @data,
      @width,
      @bits_per_pixel,
      @compression_method = Compression::Deflate,
      @deflate_speed = Compress::Deflate::BEST_SPEED
    )
    end

    def bytes_per_row
      ((@width * @bits_per_pixel) / 8).ceil.to_i32
    end

    def bytes_per_pixel
      (@bits_per_pixel // 8).clamp(1..)
    end

    def row_range(row_index)
      self.class.row_range(row_index, bytes_per_row)
    end

    def write(io : IO, filter = FilterMethod::None)
      super(io) do |idat|
        case @compression_method
        when Compression::Deflate
          Compress::Zlib::Writer.open(idat, @deflate_speed) do |deflate|
            previous_row : Bytes? = nil

            # Get each row as a sub-slice
            (@data.size // bytes_per_row).times do |row_index|
              deflate.write_byte(filter.value) # Every row of the image needs a filter byte
              row = @data[row_range(row_index)]

              case filter
              when FilterMethod::None
                deflate.write(row)
              when FilterMethod::Sub
                Scanline.new(row, bytes_per_pixel).sub(deflate)
              when FilterMethod::Up
                Scanline.new(row, bytes_per_pixel).up(previous_row, deflate)
              when FilterMethod::Average
                Scanline.new(row, bytes_per_pixel).average(previous_row, deflate)
              when FilterMethod::Paeth
                Scanline.new(row, bytes_per_pixel).paeth(previous_row, deflate)
                # when FilterMethod::Adaptive # TODO Choose the best
              else
                raise "Unsupported filter method: #{filter}"
              end

              previous_row = row
            end
          end
        else
          raise "Unsupported compression method: #{@compression_method}"
        end
      end
    end
  end
end
