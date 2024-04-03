module PNG
  struct Palette
    include Indexable::Mutable(Tuple(UInt8, UInt8, UInt8))

    property data : Bytes

    def initialize(@data)
    end

    def unsafe_fetch(index)
      real_index = index.to_u32 * 3
      r, g, b = @data[real_index..(real_index + 2)]
      {r, g, b}
    end

    def unsafe_put(index, value)
      real_index = index * 3
      real_index.upto(real_index + 2) do |i|
        @data[i] = value[i]
      end
    end

    def size
      @data.size // 3
    end

    def clone
      Palette.new(@data.clone)
    end
  end
end
