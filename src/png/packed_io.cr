module PNG
  class PackedIO < IO
    @io : IO                 # The underlying IO
    @buffer : UInt8 = 0u8    # A byte to unpack
    getter bit_depth : UInt8 # Number of bits per packed value (1, 2, or 4)
    @counter : UInt8         # The current sub byte position
    @mask : UInt8            # The current bitmask for the sub_byte
    @sub_values : UInt8      # Count of values contained in the byte (8 for 1, 4 for 2, 2 for 4)
    @scaling : Bool          # When true, convert values like 0xF @ 4bits to 0xFF at 8bits when read

    def initialize(@io, @bit_depth = 2, @scaling = false)
      # unless Bytes[1, 2, 4, 8].includes?(@bit_depth)
      #   raise ArgumentError.new("Unsupported bit depth")
      # end

      @counter = 8u8 // @bit_depth
      @mask = (1u8 << @bit_depth) - 1
      @mask = @mask.rotate_right(@bit_depth)
      @sub_values = 8u8 // @bit_depth
    end

    def read(slice : Bytes)
      if @bit_depth >= 8
        @io.read(slice)
      else
        slice.size.times { |i| slice[i] = unpack }
        slice.size
      end
    end

    def write(slice : Bytes) : Nil
      raise "Writing not implemented yet"
    end

    # Align to the next byte
    def align!
      @counter = 8u8 // @bit_depth
    end

    def unpacked_read
      raise "Bad alignment!" unless (@counter * @bit_depth) >= 8

      @io.read_bytes(UInt8)
    end

    # Convert a lower bit depth value into a higher one
    # ex: 0xF @ 4 bits becomes 0xFF @ 8 bits
    #
    private def scale(value) : UInt8
      ((value / (0xFFu8 >> (8 - @bit_depth))) * UInt8::MAX).to_u8
    end

    private def unpack
      if @counter * @bit_depth >= 8
        @buffer = @io.read_bytes(UInt8)
        @counter = 0
      end

      shift = (@sub_values - @counter - 1) * @bit_depth
      value = (@buffer & @mask) >> shift
      @counter += 1
      @mask = @mask.rotate_right(@bit_depth)
      @scaling ? scale(value) : value
    end
  end
end
