module PNG
  struct RGB(T) < Color(T, 3)
    def self.color_type
      ColorType::TrueColor
    end

    def self.from_hsv(hsv : HSV)
      h, s, v = hsv.h, hsv.s, hsv.v
      c = v * s
      x = c * (1 - ((h / 60.0) % 2 - 1).abs)
      m = v - c

      r, g, b =
        case h
        when 0...60    then {c, x, 0}
        when 60...120  then {x, c, 0}
        when 120...180 then {0, c, x}
        when 180...240 then {0, x, c}
        when 240...300 then {x, 0, c}
        else
          {c, 0, x}
        end

      r = T.new(((r + m) * T::MAX).clamp(0, T::MAX))
      g = T.new(((g + m) * T::MAX).clamp(0, T::MAX))
      b = T.new(((b + m) * T::MAX).clamp(0, T::MAX))

      RGB(T).new(r, g, b)
    end

    define_channels [r, g, b]

    def to_rgb8
      RGB(UInt8).new(
        UInt8.new(((r / T::MAX) * UInt8::MAX)),
        UInt8.new(((g / T::MAX) * UInt8::MAX)),
        UInt8.new(((b / T::MAX) * UInt8::MAX))
      )
    end
  end
end
