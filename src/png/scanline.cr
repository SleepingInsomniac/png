module PNG
  struct Scanline
    property data : Bytes
    @bytes_per_pixel : Int32

    def initialize(@data, @bytes_per_pixel)
    end

    # Run the sub filter strategy yielding each modified byte to the block
    #
    def sub(&block : UInt8 -> Nil)
      @data[...@bytes_per_pixel].each { |d| yield d }

      (@bytes_per_pixel...@data.size).each do |i|
        yield @data[i] &- @data[i - @bytes_per_pixel]
      end
    end

    # :ditto:
    def sub(io : IO)
      sub { |byte| io.write_byte(byte) }
    end

    # Subtract the previous row from this one
    #
    def up(other : Bytes, &block : UInt8 -> Nil)
      (0...@data.size).each do |i|
        yield @data[i] &- other[i]
      end
    end

    # :ditto:
    def up(other : Nil, &block : UInt8 -> Nil)
      @data.each { |d| yield d }
    end

    # :ditto:
    def up(other : Bytes?, io : IO)
      up(other) { |byte| io.write_byte(byte) }
    end
  end
end
