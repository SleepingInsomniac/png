module PNG
  # PackedData is a wrapper around a Slice *data* which performs R/W operations
  # on data packed within the type
  struct PackedData(T)
    include Indexable::Mutable(T)

    property data : Slice(T)
    getter depth : UInt8
    @size : Int32? = nil
    @begin_bit : Int32 = 0

    def initialize(@data, @depth, @size = nil, @begin_bit = 0)
    end

    def initialize(@size : Int, @depth, @begin_bit = 0)
      @data = Slice(T).new(((size * @depth) / bits).ceil.to_i32)
    end

    private getter bits : UInt8 do
      (sizeof(T) * 8).to_u8
    end

    private getter shift : UInt8 do
      (bits - @depth).to_u8
    end

    # Maximum value able to be represented by @depth
    private getter max : T do
      T::MAX >> shift
    end

    def unsafe_fetch(index : Int)
      return @data[index] if bits == @depth

      word, bit = word_bit(index)
      (@data[word] >> (shift &- bit)) & max
    end

    def unsafe_put(index : Int, value : T)
      return @data[index] = value if bits == @depth

      word, bit = word_bit(index)
      value = (value & max)
      mask = ~(max << (bits &- @depth - bit))
      value <<= (bits &- @depth - bit)
      @data[word] &= mask
      @data[word] |= value
    end

    def size
      @size || (@data.size * bits) // @depth
    end

    @[AlwaysInline]
    def word_bit(index : Int)
      (index.to_i32 * depth + @begin_bit).divmod(bits)
    end

    def [](range : Range)
      begin_word, begin_bit = word_bit(range.begin)
      end_word, _ = word_bit(range.end - 1)
      sub_slice = @data[begin_word..end_word]
      PackedData(T).new(sub_slice, @depth, range.size.to_i32, begin_bit)
    end

    def clone
      new(@data.dup, @depth, @size, @begin_bit)
    end
  end
end
