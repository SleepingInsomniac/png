require "./colors"
require "./palette"
require "../drawable"

module PNG
  # A canvas holds all of the PNG data including the header and other chunk information
  #
  class Canvas
    include Drawable

    property header : Header          # IHDR
    property data : Bytes             # IDAT
    property palette : Palette? = nil # PLTE

    property transparency : Bytes? = nil   # tRNS
    property pixel_size : PixelSize? = nil # pHYs
    property bg_color : Bytes? = nil       # bKGD
    property last_modified : Time? = nil   # tIME
    property gama : UInt32? = nil          # gAMA

    delegate :width, :height,
      :bit_depth, :bits_per_pixel, :bytes_per_pixel, :bytes_per_row,
      :color_type,
      to: @header

    def self.make(width : UInt32, height : UInt32, palette : Palette? = nil)
      canvas = new(width, height, palette)
      canvas.fill { |x, y| yield(x, y) }
    end

    def self.make(header : Header, palette : Palette? = nil)
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

    # Return the bytes corresponding to scanline
    def scanline(y)
      bpr = header.bytes_per_row
      index = y * bpr
      @data[index...(index + bpr)]
    end

    # Copy the ancillarry data to a new canvas
    def copy_ancilarry(to : Canvas)
      to.transparency = @transparency.dup
      to.pixel_size = @pixel_size.dup
      to.bg_color = @bg_color.dup
      to.last_modified = @last_modified.dup
      to.gama = @gama.dup
    end

    # Return a deep clone of this canvas
    def clone
      self.class.new(@header.dup, @data.dup, @palette.clone).tap do |new_canvas|
        copy_ancilarry(new_canvas)
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

    def []=(x : UInt32, y : UInt32, c : Int, value : UInt8)
      raise Error.new("Channel out of range") if c > @header.bytes_per_pixel

      row = scanline(y)
      channels = color_type.channels
      n = x * channels

      case bit_depth
      when .<= 8 then PackedData(UInt8).new(row, bit_depth)[n + c] = value
      when 8     then row[n + c] = value
      when 16    then row[n * 2 + c] = value
      else
        raise Error.new("Invalid bit depth: #{bit_depth}")
      end
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
    def []=(x : UInt32, y : UInt32, values : Indexable(UInt8))
      if values.size != @header.bytes_per_pixel
        raise Error.new("Value must correspond to bit depth and channel count " \
                        "(#{@header.bytes_per_pixel} bytes)")
      end

      row = scanline(y)
      channels = color_type.channels
      n = x * channels

      case bit_depth
      when .<= 8
        PackedData(UInt8).new(row, bit_depth)[n...(n + channels)].map_with_index! { |v, i| values[i] }
      when 8
        row[n...(n + channels)].map_with_index! { |v, i| values[i] }
      when 16
        row[(n * 2)...(n * 2 + channels * 2)].map_with_index! { |v, i| values[i] }
      else
        raise Error.new("Invalid bit depth: #{bit_depth}")
      end
    end

    def []=(x, y, values : Enumerable(Number))
      self[x, y] = bit_depth <= 8 ? values.map(&.to_u8) : values.map(&.to_u16)
    end

    def []=(x, y, values : Enumerable(UInt8))
      self[x.to_u32, y.to_u32] = values
    end

    def []=(x, y, values : Enumerable(UInt16))
      values.each_with_index do |v, i|
        low_byte = (v & 255u8).to_u8
        high_byte = ((v >> 8) & 255u8).to_u8

        self[x.to_u32, y.to_u32, i * 2] = high_byte
        self[x.to_u32, y.to_u32, i * 2 + 1] = low_byte
      end
    end

    def []=(x, y, value : Int)
      self[x, y, 0] = value.to_u8
    end

    # Get the data at x, y into the canvas.
    # This returns the Bytes that represent the pixel.
    def [](x : UInt32, y : UInt32)
      row = scanline(y)
      channels = color_type.channels
      n = x * channels

      case bit_depth
      when .<= 8 then PackedData(UInt8).new(row, bit_depth)[n...(n + channels)]
      when 8     then row[n...(n + channels)]
      when 16    then row[(n * 2)...(n * 2 + channels * 2)]
      else            raise Error.new("Invalid bit depth: #{bit_depth}")
      end
    end

    # :ditto:
    def [](x : Number, y : Number)
      self[x.to_u32, y.to_u32]
    end

    # Get the color at x, y
    def color(x, y) : Enumerable
      @header.colorize(self[x.to_u32, y.to_u32], @palette)
    end

    # Set a color at x, y
    def set_color(x, y, color : Enumerable)
      self[x, y] = color
    end

    # Crop a canvas in absolute coordinates
    def crop(start_x : Int, start_y : Int, end_x : Int, end_y : Int) # : Canvas
      start_x, end_x = end_x, start_x if start_x > end_x
      start_y, end_y = end_y, start_y if start_y > end_y

      new_header = @header.dup
      new_header.width = (end_x - start_x).to_u32
      new_header.height = (end_y - start_y).to_u32

      Canvas.make(new_header, @palette.clone) do |x, y|
        if ((start_x + x) >= 0 && (x + start_x < width)) &&
           ((start_y + y) >= 0 && (y + start_y < height))
          self[x + start_x, y + start_y]
        end
      end.tap { |c| copy_ancilarry(c) }
    end

    def resize_nearest_neighbor(width, height)
      new_header = @header.dup
      new_header.width = width.to_u32
      new_header.height = height.to_u32
      new_canvas = self.class.new(new_header, palette: @palette.clone)
      copy_ancilarry(new_canvas)
      Drawable.resize_nearest_neighbor(self, new_canvas)
    end

    def resize_bilinear(width, height)
      new_header = @header.dup
      new_header.width = width.to_u32
      new_header.height = height.to_u32
      new_canvas = self.class.new(new_header, palette: @palette.clone)
      copy_ancilarry(new_canvas)
      Drawable.resize_bilinear(self, new_canvas)
    end
  end
end
