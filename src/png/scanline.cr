module PNG
  # @see https://www.w3.org/TR/png-3/#9Filters
  #
  struct Scanline
    property data : Bytes
    @bytes_per_pixel : Int32

    def initialize(@data, @bytes_per_pixel)
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Remove the sub filter (in place)
    #
    def unsub!
      (@bytes_per_pixel...@data.size).each do |x|
        a = x - @bytes_per_pixel
        @data[x] = @data[x] &+ @data[a]
      end
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Remove the up filter
    #
    def unup!(other : Bytes)
      other.try do |other|
        (0...@data.size).each do |i|
          @data[i] = @data[i] &+ other[i]
        end
      end
    end

    # :ditto:
    def unup!(other : Nil)
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Apply the average filter
    # `Filt(x) = Orig(x) - floor((Orig(a) + Orig(b)) / 2)`
    #
    def average(other : Bytes, &block : UInt8 -> Nil)
      (0...@data.size).each do |i|
        b = other[i]
        a = i < @bytes_per_pixel ? 0u16 : @data[i - @bytes_per_pixel].to_u16
        yield @data[i] &- ((a + b) >> 1)
      end
    end

    # :ditto:
    def average(other : Nil, &block : UInt8 -> Nil)
      (0...@data.size).each do |i|
        a = i < @bytes_per_pixel ? 0u16 : @data[i - @bytes_per_pixel].to_u16
        yield @data[i] &- (a >> 1)
      end
    end

    # :ditto:
    def average(other : Bytes?, io : IO)
      average(other) { |byte| io.write_byte(byte) }
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Removes the type 3 Average filter via:
    # `Recon(x) = Filt(x) + floor((Recon(a) + Recon(b)) / 2)`
    #
    def unaverage!(other : Bytes)
      (0...@data.size).each do |i|
        b = other[i]
        a = i < @bytes_per_pixel ? 0u16 : @data[i - @bytes_per_pixel].to_u16
        @data[i] = @data[i] &+ ((a + b) >> 1)
      end
    end

    # :ditto:
    def unaverage!(other : Nil)
      (0...@data.size).each do |i|
        a = i < @bytes_per_pixel ? 0u8 : @data[i - @bytes_per_pixel]
        @data[i] = @data[i] &+ (a >> 1)
      end
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Use the Paeth filter strategy
    #
    def paeth(other : Bytes, &block : UInt8 -> Nil)
      (0...@data.size).each do |i|
        b = other[i]
        a = i < @bytes_per_pixel ? 0u8 : @data[i - @bytes_per_pixel]
        c = i < @bytes_per_pixel ? 0u8 : other[i - @bytes_per_pixel]

        yield @data[i] &- paeth_predict(a, b, c)
      end
    end

    # :ditto:
    def paeth(other : Nil, &block : UInt8 -> Nil)
      (0...@data.size).each do |i|
        b = 0u8
        a = i < @bytes_per_pixel ? 0u8 : @data[i - @bytes_per_pixel]
        c = 0u8

        yield @data[i] &- paeth_predict(a, b, c)
      end
    end

    # :ditto:
    def paeth(other : Bytes?, io : IO)
      paeth(other) { |byte| io.write_byte(byte) }
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Remove the Paeth filter type
    # `Recon(x) = Filt(x) + PaethPredictor(Recon(a), Recon(b), Recon(c))`
    #
    def unpaeth!(other : Bytes)
      (0...@data.size).each do |i|
        b = other[i]
        a = i < @bytes_per_pixel ? 0u8 : @data[i - @bytes_per_pixel]
        c = i < @bytes_per_pixel ? 0u8 : other[i - @bytes_per_pixel]

        @data[i] = @data[i] &+ paeth_predict(a, b, c)
      end
    end

    # :ditto:
    def unpaeth!(other : Nil)
      (0...@data.size).each do |i|
        b = 0u8
        a = i < @bytes_per_pixel ? 0u8 : @data[i - @bytes_per_pixel]
        c = 0u8

        @data[i] = @data[i] &+ paeth_predict(a, b, c)
      end
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # https://www.w3.org/TR/png-3/#bib-paeth
    #
    def paeth_predict(a, b, c)
      a, b, c = a.to_i16, b.to_i16, c.to_i16
      p = a + b - c
      pa = (p - a).abs
      pb = (p - b).abs
      pc = (p - c).abs

      if pa <= pb && pa <= pc
        a
      elsif pb <= pc
        b
      else
        c
      end
    end
  end
end
