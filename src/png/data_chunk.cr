require "compress/zlib"

module PNG
  struct DataChunk < Chunk
    @filter : FilterMethod

    def initialize(@filter = FilterMethod::None)
      @chunk_type = "IDAT"
    end

    def write(io : IO, data : Bytes, bytes_per_row : Int, compression_method = Compression::Deflate, deflate_speed = Compress::Deflate::BEST_SPEED)
      super(io) do |idat|
        case compression_method
        when Compression::Deflate
          Compress::Zlib::Writer.open(idat, deflate_speed) do |deflate|
            # Get each row as a sub-slice
            (data.size // bytes_per_row).times do |row_index|
              start_index = row_index * bytes_per_row
              end_index = start_index + bytes_per_row

              # Ideally this would be tested to determine the smallest filter type
              deflate.write_byte(FilterMethod::None.value) # Every row of the image needs a filter byte
              deflate.write(data[start_index...end_index])
            end
          end
        else
          raise "Unsupported compression method: #{compression_method}"
        end
      end
    end
  end
end
