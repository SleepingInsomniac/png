module PNG
  struct Gray(T)
    property g : T

    def initialize(@g)
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
