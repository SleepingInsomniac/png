module PNG
  struct RGBA(T) < Color(T, 4)
    def self.color_type
      ColorType::TrueColorAlpha
    end

    define_channels [r, g, b, a]

    def initialize(r : T, g : T, b : T)
      initialize(r, g, b, T::MAX)
    end

    def to_rgb8
      alpha = (a / T::MAX)
      RGB(UInt8).new(
        UInt8.new(((r / T::MAX) * alpha) * UInt8::MAX),
        UInt8.new(((g / T::MAX) * alpha) * UInt8::MAX),
        UInt8.new(((b / T::MAX) * alpha) * UInt8::MAX)
      )
    end

    # via luminosity method
    def to_g8
      rgb8 = to_rgb8
      g = 0.3 * rgb8.r + 0.59 * rgb8.g + 0.11 * rgb8.b
      Gray(UInt8).new(UInt8.new(g.floor))
    end
  end
end
