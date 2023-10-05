require "compress/zlib"
require "./scanline"

module PNG
  class DataChunk < Chunk
    TYPE = "IDAT"
    @chunk_type = TYPE

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
    def self.unfilter(filtered : IO, width : Int, height : Int, bytes_per_pixel : Int)
      bytes_per_row = width * bytes_per_pixel
      data = Bytes.new((width * bytes_per_pixel) * height)
      previous_row : Bytes? = nil

      height.times do |row_index|
        filter = FilterMethod.new(filtered.read_bytes(UInt8))
        row = data[row_range(row_index, bytes_per_row)]
        filtered.read_fully(row)

        case filter
        when FilterMethod::None # Nothing to do. Yay!
        when FilterMethod::Sub
          Scanline.new(row, bytes_per_pixel).unsub!
        when FilterMethod::Up
          Scanline.new(row, bytes_per_pixel).unup!(previous_row)
        when FilterMethod::Average
          Scanline.new(row, bytes_per_pixel).unaverage!(previous_row)
        when FilterMethod::Paeth # TODO
          Scanline.new(row, bytes_per_pixel).unpaeth!(previous_row)
        else
          raise "Unsupported filter method: #{filter}"
        end

        previous_row = row
      end

      new(data, width, bytes_per_pixel)
    end

    getter data : Bytes
    @width : UInt32
    getter bytes_per_pixel : Int32
    @filter : FilterMethod = FilterMethod::None
    @compression_method = Compression::Deflate
    @deflate_speed = Compress::Deflate::BEST_SPEED

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
      self.class.row_range(row_index, bytes_per_row)
    end

    def write(io : IO)
      super(io) do |idat|
        case @compression_method
        when Compression::Deflate
          Compress::Zlib::Writer.open(idat, @deflate_speed) do |deflate|
            previous_row : Bytes? = nil

            # Get each row as a sub-slice
            (@data.size // bytes_per_row).times do |row_index|
              deflate.write_byte(@filter.value) # Every row of the image needs a filter byte
              row = @data[row_range(row_index)]

              case @filter
              when FilterMethod::None
                deflate.write(row)
              when FilterMethod::Sub
                Scanline.new(row, @bytes_per_pixel).sub(deflate)
              when FilterMethod::Up
                Scanline.new(row, @bytes_per_pixel).up(previous_row, deflate)
              when FilterMethod::Average
                Scanline.new(row, @bytes_per_pixel).average(previous_row, deflate)
              when FilterMethod::Paeth
                Scanline.new(row, @bytes_per_pixel).paeth(previous_row, deflate)
                # when FilterMethod::Adaptive
              else
                raise "Unsupported filter method: #{@filter}"
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
