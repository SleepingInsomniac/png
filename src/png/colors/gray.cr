module PNG
  struct Gray(T) < Color(T, 1)
    def self.color_type
      ColorType::Grayscale
    end

    define_channels [g]

    def to_rgb8
      v = UInt8.new(((g / T::MAX) * UInt8::MAX))
      RGB(UInt8).new(v, v, v)
    end
  end
end
