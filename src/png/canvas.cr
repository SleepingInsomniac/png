require "./colors/hsv"
require "./colors/rgb"
require "./colors/rgba"
require "./colors/gray"
require "./colors/gray_alpha"

module PNG
  class Canvas
    property header : Header
    property data : Bytes
    property palette : Bytes? = nil

    delegate :width, :height,
      :bit_depth, :bits_per_pixel, :bytes_per_pixel, :bytes_per_row,
      :color_type,
      to: @header

    def initialize(width : UInt32, height : UInt32, @palette = nil)
      if @palette.nil?
        @header = Header.new(width, height)
      else
        @header = Header.new(width, height, color_type: ColorType::Indexed)
      end
      @data = Bytes.new(@header.byte_size)
    end

    def initialize(@header, data : Bytes? = nil, @palette = nil)
      if d = data
        @data = d
      else
        @data = Bytes.new(@header.byte_size)
      end
    end

    def interlaced? : Bool
      !@header.interlacing.none?
    end

    # Calculates the index into the canvas that a value would be at, accounting
    # for padding that would exist at the end of a scanline where bit depth < 8
    def bit_index(x : UInt32, y : UInt32)
      (y * header.bytes_per_row * 8) + (x * @header.bits_per_pixel)
    end

    def byte_index(x : UInt32, y : UInt32)
      bit_index(x, y) // 8
    end

    # Set the pixel at x, y into the canvas
    def []=(x : UInt32, y : UInt32, values : Enumerable(UInt8))
      if values.size != @header.bytes_per_pixel
        raise Error.new("Value must correspond to bit depth and channel count " \
                        "(#{@header.bytes_per_pixel} bytes)")
      end

      case @header.bit_depth
      when .< 8 # Officially 1, 2, 4
        shift = 8u8 - @header.bit_depth
        max = UInt8::MAX >> shift
        bit_offset = bit_index(x, y)

        @header.channels.times do |n|
          offset, bit = (bit_offset + (bit_depth * n)).divmod(8)
          @data[offset] |= values[n] << (8 &- @header.bit_depth - bit)
        end
      when 8, 16
        offset = byte_index(x, y)
        values.each_with_index { |v, n| @data[offset + n] = v }
      else
        raise Error.new("Invalid bit depth: #{@header.bit_depth}")
      end
    end

    def []=(x : Int, y : Int, values)
      self[x.to_u32, y.to_u32] = values
    end

    # Get the pixel at x, y into the canvas
    def [](x : UInt32, y : UInt32)
      case @header.bit_depth
      when .< 8
        bit_offset = bit_index(x, y)

        shift = 8u8 - @header.bit_depth
        max = UInt8::MAX >> shift

        Bytes.new(@header.color_type.channels.to_i32) do |n|
          offset, bit = (bit_offset + (n * @header.bit_depth)).divmod(8)
          (@data[offset] >> (shift &- bit)) & max
        end
      when 8, 16
        offset = byte_index(x, y)
        @data[offset...(offset + @header.bytes_per_pixel)]
      else
        raise Error.new("Invalid bit depth: #{@header.bit_depth}")
      end
    end

    def [](x : Int, y : Int)
      self[x.to_u32, y.to_u32]
    end

    # Get the color at x, y
    def color(x, y)
      @header.colorize(self[x, y], @palette)
    end
  end
end
