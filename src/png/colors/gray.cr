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

    def to_g8
      {% if T == UInt8 %}
        self
      {% else %}
        v = UInt8.new(((g / T::MAX) * UInt8::MAX))
        Gray(UInt8).new(v)
      {% end %}
    end
  end
end
