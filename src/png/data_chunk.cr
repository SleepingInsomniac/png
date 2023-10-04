require "compress/zlib"
require "./scanline"

module PNG
  struct DataChunk < Chunk
    @data : Bytes
    @width : UInt32
    @bytes_per_pixel : Int32
    @filter : FilterMethod = FilterMethod::None
    @compression_method = Compression::Deflate
    @deflate_speed = Compress::Deflate::BEST_SPEED
    @chunk_type = "IDAT"

    def initialize(
      @data,
      @width,
      @bytes_per_pixel,
      @filter = FilterMethod::None,
      @compression_method = Compression::Deflate,
      @deflate_speed = Compress::Deflate::BEST_SPEED
    )
    end

    def bytes_per_row
      @width * @bytes_per_pixel
    end

    def row_range(row_index)
      start_index = row_index * bytes_per_row
      end_index = start_index + bytes_per_row
      start_index...end_index
    end

    def write(io : IO)
      super(io) do |idat|
        case @compression_method
        when Compression::Deflate
          Compress::Zlib::Writer.open(idat, @deflate_speed) do |deflate|
            # Get each row as a sub-slice
            (@data.size // bytes_per_row).times do |row_index|
              deflate.write_byte(@filter.value) # Every row of the image needs a filter byte

              case @filter
              when FilterMethod::None
                deflate.write(@data[row_range(row_index)])
              when FilterMethod::Sub
                Scanline.new(@data[row_range(row_index)], @bytes_per_pixel).sub(deflate)
              when FilterMethod::Up
                line = Scanline.new(@data[row_range(row_index)], @bytes_per_pixel)
                previous_line = row_index == 0 ? nil : @data[row_range(row_index - 1)]
                line.up(previous_line, deflate)
                # when FilterMethod::Average # TODO
                # when FilterMethod::Paeth # TODO
                # when FilterMethod::Adaptive # TODO
              else
                raise "Unsupported filter type: #{@filter}"
              end
            end
          end
        else
          raise "Unsupported compression method: #{@compression_method}"
        end
      end
    end
  end
end
