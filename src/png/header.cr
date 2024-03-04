require "./enums/*"
require "./pixel_size"

module PNG
  struct Header
    property width : UInt32
    property height : UInt32
    property bit_depth : UInt8
    property color_type : ColorType
    property compression_method : CompressionMethod
    property filter_type : FilterType
    property interlacing : Interlacing

    delegate :channels, to: @color_type

    def self.parse(io : IO)
      new(
        width: io.read_bytes(UInt32, IO::ByteFormat::BigEndian),
        height: io.read_bytes(UInt32, IO::ByteFormat::BigEndian),
        bit_depth: io.read_bytes(UInt8),
        color_type: ColorType.new(io.read_bytes(UInt8)),
        compression_method: CompressionMethod.new(io.read_bytes(UInt8)),
        filter_type: FilterType.new(io.read_bytes(UInt8)),
        interlacing: Interlacing.new(io.read_bytes(UInt8))
      )
    end

    def initialize(
      @width,
      @height,
      @bit_depth = 8u8,
      @color_type = ColorType::TrueColor,
      @compression_method = CompressionMethod::Deflate,
      @filter_type = FilterType::Adaptive,
      @interlacing = Interlacing::None
    )
      raise Error.new("Invalid bit depth: #{@bit_depth}") if @bit_depth < 1 || @bit_depth > 16
    end

    # Number of bits to represent a pixel. Ex: 4bits @ rgb color would be `4 * 3 = 12`
    def bits_per_pixel : UInt32
      @color_type.channels.to_u32 * @bit_depth.to_u32
    end

    # Number of bytes to represent a pixel. Ex: 4bits @ rgb color would be `ceil((4 * 3) / 8) = 2`
    # This includes extra padding.
    def bytes_per_pixel : UInt8
      (@color_type.channels * (@bit_depth / 8)).clamp(1..).ceil.to_u8
    end

    # Row size including padding where bit depth doesn't align to bytes. Not including filter byte.
    def bytes_per_row(width : Int = @width)
      ((bits_per_pixel * width) / 8).ceil.to_u32
    end

    # Total bytesize including row padding, not including filter bytes
    def byte_size
      bytes_per_row * height
    end

    # Convert bytes into a color struct
    def colorize(colors : Bytes, palette : Bytes? = nil)
      if bit_depth < 8 && !color_type.indexed?
        # Convert a lower bit value to it's 8bit equivalent
        shift = 8u8 - bit_depth
        max = UInt8::MAX >> shift
        colors = colors.map { |c| UInt8.new((c / max) * UInt8::MAX) }
      end

      if bit_depth == 16
        colors = colors.each_slice(2).map { |(b0, b1)| (b0.to_u16 << 8) | b1 }.to_a.as(Array(UInt16))

        case color_type
        when .grayscale?        then Gray(UInt16).new(colors[0])
        when .grayscale_alpha?  then GrayAlpha(UInt16).new(colors[0], colors[1])
        when .true_color?       then RGB(UInt16).new(colors[0], colors[1], colors[2])
        when .true_color_alpha? then RGBA(UInt16).new(colors[0], colors[1], colors[2], colors[3])
        else
          raise Error.new("Invalid color type: #{color_type} for #{bit_depth} bits")
        end
      else
        colors = colors.as(Slice(UInt8))
        case color_type
        when .indexed?
          if p = palette
            p_index = colors[0].to_u32 * 3
            r, g, b = palette[p_index..(p_index + 2)]
            RGB(UInt8).new(r, g, b)
          else
            raise Error.new("Palette required for indexed images")
          end
        when .grayscale?        then Gray(UInt8).new(colors[0])
        when .grayscale_alpha?  then GrayAlpha(UInt8).new(colors[0], colors[1])
        when .true_color?       then RGB(UInt8).new(colors[0], colors[1], colors[2])
        when .true_color_alpha? then RGBA(UInt8).new(colors[0], colors[1], colors[2], colors[3])
        else
          raise Error.new("Invalid color type: #{color_type} for #{bit_depth} bits")
        end
      end
    end

    def write(io : IO)
      Chunk.write("IHDR", io, 13) do |data|
        data.write_bytes(@width, IO::ByteFormat::BigEndian)
        data.write_bytes(@height, IO::ByteFormat::BigEndian)
        data.write_byte(@bit_depth)
        data.write_byte(@color_type.value)
        data.write_byte(@compression_method.value)
        data.write_byte(@filter_type.value)
        data.write_byte(@interlacing.value)
      end
    end
  end
end
