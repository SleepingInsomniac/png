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
    def data_size
      bytes_per_row * height
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
