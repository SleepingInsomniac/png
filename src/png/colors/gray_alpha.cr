module PNG
  struct GrayAlpha(T)
    property g : T
    property a : T

    def initialize(@g, @a = T::MAX)
    end

    def to_rgb8
      RGB(UInt8).new(
        UInt8.new(((g / T::MAX) * UInt8::MAX)),
        UInt8.new(((g / T::MAX) * UInt8::MAX)),
        UInt8.new(((g / T::MAX) * UInt8::MAX))
      )
    end
  end
end
