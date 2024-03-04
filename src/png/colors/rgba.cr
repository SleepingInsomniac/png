module PNG
  struct RGBA(T) < Color(T, 4)
    def self.color_type
      ColorType::TrueColorAlpha
    end

    define_channels [r, g, b, a]

    def to_rgb8
      alpha = (a / T::MAX)
      RGB(UInt8).new(
        UInt8.new(((r / T::MAX) * alpha) * UInt8::MAX),
        UInt8.new(((g / T::MAX) * alpha) * UInt8::MAX),
        UInt8.new(((b / T::MAX) * alpha) * UInt8::MAX)
      )
    end
  end
end
