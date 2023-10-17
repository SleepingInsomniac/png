module PNG
  struct Options
    property bit_depth : UInt8 # 1, 2, 4, 8, or 16
    property color_type : ColorType
    property compression_method : Compression # deflate is the only supported method
    property interlacing : Interlacing

    def initialize(
      @bit_depth = 8u8,
      @color_type = ColorType::TrueColor,
      @compression_method = Compression::Deflate,
      @interlacing = Interlacing::None
    )
    end

    def bits_per_pixel : UInt32
      @color_type.channels.to_u32 * @bit_depth.to_u32
    end

    def bytes_per_pixel : UInt8
      (bits_per_pixel / 8).ceil.to_u8
    end

    def bytes_per_row(width : Int)
      ((bits_per_pixel * width) / 8).ceil.to_u32
    end
  end
end
