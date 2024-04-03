require "./enums/filter_method"

module PNG
  # A row of pixels including their filtering method
  struct Scanline
    property header : Header
    property filter : FilterMethod
    property data : Bytes

    delegate :[], :[]?, to: @data
    delegate :bytes_per_pixel, :bits_per_pixel, :bit_depth, :channels, to: @header

    def initialize(@header, @filter, @data)
    end

    # Sets a pixel in this scanline based on the header
    #
    def set_pixel(x : Int, values : Indexable(UInt8)) : Nil
      case bit_depth
      when .< 8
        i = x * channels
        pd = PackedData(UInt8).new(@data, bit_depth)[i...(i + channels)]
        values.each_with_index { |v, i| pd[i] = v }
      when 8, 16
        byte = x * bytes_per_pixel
        values.each_with_index { |v, n| @data[byte + n] = v }
      else
        raise Error.new("Invalid bit depth: #{bit_depth}")
      end
    end

    # Return the bytes that represent a pixel at x in this scanline
    def pixel(x : Int) : Indexable(UInt8)
      case bit_depth
      when .< 8
        i = x * channels
        PackedData(UInt8).new(@data, bit_depth)[i...(i + channels)]
      when 8, 16
        byte = x * bytes_per_pixel
        @data[byte...(byte + bytes_per_pixel)]
      else
        raise Error.new("Invalid bit depth: #{bit_depth}")
      end
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Remove any filtering in this scanline
    # @see https://www.w3.org/TR/png-3/#9Filters
    def unfilter(previous : Scanline?)
      case @filter
      when FilterMethod::None
      when FilterMethod::Sub     then unsub
      when FilterMethod::Up      then unup(previous)
      when FilterMethod::Average then unaverage(previous)
      when FilterMethod::Paeth   then unpaeth(previous)
      else                            PNG.debug "Unsupported filter method: #{@filter}"
      end
    end

    # Apply a filter
    def filter(previous : Scanline?, &block : UInt8 -> Nil)
      case @filter
      when FilterMethod::None    then none(&block)
      when FilterMethod::Sub     then sub(&block)
      when FilterMethod::Up      then up(previous, &block)
      when FilterMethod::Average then average(previous, &block)
      when FilterMethod::Paeth   then paeth(previous, &block)
      else                            PNG.debug "Unsupported filter method: #{@filter}"
      end
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    def none
      @data.each { |d| yield d }
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Remove the sub filter
    # Recon(x) = Filt(x) + Recon(a)
    def unsub
      bytes = bytes_per_pixel

      (bytes.to_u32...@data.size).each do |x|
        a = x - bytes
        @data[x] = @data[x] &+ @data[a]
      end
    end

    # Filt(x) = Orig(x) - Orig(a)
    # Run the sub filter strategy yielding each modified byte to the block
    def sub(&block : UInt8 -> Nil)
      bytes = bytes_per_pixel
      @data[...bytes].each { |d| yield d }

      (bytes...@data.size).each do |x|
        a = x - bytes
        yield @data[x] &- @data[a]
      end
    end

    # :ditto:
    def sub(io : IO)
      sub { |byte| io.write_byte(byte) }
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Remove the up filter
    def unup(other : Scanline?)
      other.try do |other|
        (0...@data.size).each do |i|
          @data[i] = @data[i] &+ (other[i]? || 0u8)
        end
      end
    end

    # Filt(x) = Orig(x) - Orig(b)
    def up(other : Scanline, &block : UInt8 -> Nil)
      (0...@data.size).each do |i|
        yield @data[i] &- other[i]
      end
    end

    # :ditto:
    def up(other : Nil, &block : UInt8 -> Nil)
      @data.each { |d| yield d }
    end

    # :ditto:
    def up(other : Scanline?, io : IO)
      up(other) { |byte| io.write_byte(byte) }
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Removes the type 3 Average filter via:
    # `Recon(x) = Filt(x) + floor((Recon(a) + Recon(b)) / 2)`
    def unaverage(other : Scanline)
      bytes = bytes_per_pixel

      (0...@data.size).each do |i|
        b = other[i]
        a = i < bytes ? 0u16 : @data[i - bytes].to_u16
        @data[i] = @data[i] &+ ((a + b) >> 1)
      end
    end

    # :ditto:
    def unaverage(other : Nil)
      bytes = bytes_per_pixel

      (0...@data.size).each do |i|
        a = i < bytes ? 0u8 : @data[i - bytes]
        @data[i] = @data[i] &+ (a >> 1)
      end
    end

    # Filt(x) = Orig(x) - floor((Orig(a) + Orig(b)) / 2)
    def average(other : Scanline, &block : UInt8 -> Nil)
      bytes = bytes_per_pixel

      (0...@data.size).each do |i|
        b = other[i]
        a = i < bytes ? 0u16 : @data[i - bytes].to_u16
        yield @data[i] &- ((a + b) >> 1)
      end
    end

    # :ditto:
    def average(other : Nil, &block : UInt8 -> Nil)
      bytes = bytes_per_pixel

      (0...@data.size).each do |i|
        a = i < bytes ? 0u16 : @data[i - bytes].to_u16
        yield @data[i] &- (a >> 1)
      end
    end

    # :ditto:
    def average(other : Scanline?, io : IO)
      average(other) { |byte| io.write_byte(byte) }
    end

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    # Remove the Paeth filter type
    # `Recon(x) = Filt(x) + PaethPredictor(Recon(a), Recon(b), Recon(c))`
    def unpaeth(other : Scanline)
      bytes = bytes_per_pixel

      (0...@data.size).each do |i|
        b = other[i]
        a = i < bytes ? 0u8 : @data[i - bytes]
        c = i < bytes ? 0u8 : other[i - bytes]

        @data[i] = @data[i] &+ paeth_predict(a, b, c)
      end
    end

    # :ditto:
    def unpaeth(other : Nil)
      bytes = bytes_per_pixel

      (0...@data.size).each do |i|
        b = 0u8
        a = i < bytes ? 0u8 : @data[i - bytes]
        c = 0u8

        @data[i] = @data[i] &+ paeth_predict(a, b, c)
      end
    end

    # Filt(x) = Orig(x) - PaethPredictor(Orig(a), Orig(b), Orig(c))
    def paeth(other : Scanline, &block : UInt8 -> Nil)
      bytes = bytes_per_pixel

      (0...@data.size).each do |i|
        b = other[i]
        a = i < bytes ? 0u8 : @data[i - bytes]
        c = i < bytes ? 0u8 : other[i - bytes]

        yield @data[i] &- paeth_predict(a, b, c)
      end
    end

    # :ditto:
    def paeth(other : Nil, &block : UInt8 -> Nil)
      bytes = bytes_per_pixel

      (0...@data.size).each do |i|
        b = 0u8
        a = i < bytes ? 0u8 : @data[i - bytes]
        c = 0u8

        yield @data[i] &- paeth_predict(a, b, c)
      end
    end

    # :ditto:
    def paeth(other : Scanline?, io : IO)
      paeth(other) { |byte| io.write_byte(byte) }
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
