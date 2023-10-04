module PNG
  struct Options
    property bit_depth : UInt8 # 1, 2, 4, 8, or 16
    property color_type : ColorType
    property compression_method : Compression # deflate is the only supported method
    property interlacing : Interlacing
    getter bytes_per_pixel : Int32

    def initialize(
      @bit_depth = 8u8,
      @color_type = ColorType::TrueColor,
      @compression_method = Compression::Deflate,
      @interlacing = Interlacing::None
    )
      bytes = case @color_type
              when ColorType::Grayscale      then 1
              when ColorType::TrueColor      then 3
              when ColorType::Indexed        then 1
              when ColorType::GrayscaleAlpha then 2
              when ColorType::TrueColorAlpha then 4
              else
                raise "Invalid color type #{@color_type}"
              end
      @bytes_per_pixel = (bytes * @bit_depth) // 8
    end
  end
end
