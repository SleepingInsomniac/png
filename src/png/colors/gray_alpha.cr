module PNG
  struct GrayAlpha(T) < Color(T, 2)
    def self.color_type
      ColorType::GrayscaleAlpha
    end

    define_channels [g, a]

    def to_rgb8
      alpha = (a / T::MAX)
      v = UInt8.new(((g / T::MAX) * alpha) * UInt8::MAX)
      RGB(UInt8).new(v, v, v)
    end

    def to_g8
      alpha = (a / T::MAX)
      v = UInt8.new(((g / T::MAX) * alpha) * UInt8::MAX)
      Gray(UInt8).new(v)
    end
  end
end
