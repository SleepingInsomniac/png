module PNG
  struct RGBA(T)
    property r : T
    property g : T
    property b : T
    property a : T = T::MAX

    def initialize(@r, @g, @b, @a = T::MAX)
    end

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
