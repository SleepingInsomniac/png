require "./colors"

module PNG
  # A canvas holds all of the PNG data including the header and other chunk information
  #
  class Canvas
    property header : Header               # IHDR
    property data : Bytes                  # IDAT
    property palette : Bytes? = nil        # PLTE
    property pixel_size : PixelSize? = nil # pHYs
    property bg_color : Bytes? = nil       # bKGD
    property last_modified : Time? = nil   # tIME
    property gama : UInt32? = nil          # gAMA

    delegate :width, :height,
      :bit_depth, :bits_per_pixel, :bytes_per_pixel, :bytes_per_row,
      :color_type,
      to: @header

    def self.make(width : UInt32, height : UInt32, palette : Bytes? = nil)
      canvas = new(width, height, palette)
      canvas.fill { |x, y| yield(x, y) }
    end

    def self.make(header : Header, palette : Bytes? = nil)
      canvas = new(header: header, palette: palette)
      canvas.fill { |x, y| yield(x, y) }
    end

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

    # Iterate over each x, y coordinate and set the pixel value.
    def fill(& : UInt32, UInt32 -> Enumerable(UInt8)?)
      0u32.upto(height - 1) do |y|
        0u32.upto(width - 1) do |x|
          if c = yield(x, y)
            self[x, y] = c
          end
        end
      end
      self
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

    # Set the pixel at *x*, *y* on the canvas via bytes that correspond to the
    # color type and bit depth.
    #
    # For example, an image with 8bits per channel in RGB (`PNG::ColorType::TrueColor`)
    # would be set with 3 bytes: `canvas[0, 0] = Bytes[255, 0, 255]`
    #
    # A canvas with 16bits in RGB would accept 6 bytes, (2 bytes per channel):
    # `canvas[0, 0] = Bytes[255, 255, 0, 0, 255, 255]`
    #
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

        values.each_with_index do |value, n|
          offset, bit = (bit_offset + (bit_depth * n)).divmod(8)
          @data[offset] |= value << (8 &- @header.bit_depth - bit)
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

    # Get the pixel at x, y into the canvas.
    # This returns the Bytes that represent the pixel.
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
        @data[offset...(offset + @header.bytes_per_pixel)].dup
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

    # Set a color at x, y
    def set_color(x, y, color : Color)
      self[x, y] = color
    end

    # Crop a canvas in absolute coordinates
    def crop(start_x : Int, start_y : Int, end_x : Int, end_y : Int) # : Canvas
      new_header = @header.dup
      new_header.width = (end_x - start_x).to_u32
      new_header.height = (end_y - start_y).to_u32

      Canvas.make(new_header, palette: @palette.dup) do |x, y|
        if ((start_x + x) > 0 && (x + start_x < width)) &&
           ((start_y + y) > 0 && (y + start_y < height))
          self[x + start_x, y + start_y]
        end
      end
    end
  end
end
