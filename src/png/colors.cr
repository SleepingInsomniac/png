module PNG
  abstract struct Color(T, N)
    include Enumerable(T)
    property channels : StaticArray(T, N)

    macro [](*args)
      {{ @type.name(generic_args: false) }}(typeof({{args.splat}})).new(
        {% for arg in args %}
          {{ arg }},
        {% end %}
      )
    end

    def initialize(@channels)
    end

    delegate :[], :[]=, :each, to: @channels

    def num_channels
      N
    end

    def bytesize
      sizeof(T) * N
    end

    def to_slice
      @channels.to_slice
    end

    def to_bytes
      c = @channels.dup
      ptr = pointerof(c).as(Pointer(UInt8))
      bytes = Slice.new(ptr, bytesize)

      @channels.each do |c|
        c = c.byte_swap
        sizeof(T).times do |i|
          bytes[i] = (c & 255).to_u8
          c >>= 8
        end
      end

      bytes
    end

    def ==(other)
      @channels == other.channels
    end

    macro define_channels(names)
      def self.[]({% for name in names %}{{name}} : T, {% end %})
        {{ @type.name }}.new({% for name in names %}{{ name }}, {% end %})
      end

      def initialize(@channels : StaticArray(T, N))
      end

      def initialize({% for name in names %}{{name}} : T, {% end %})
        @channels = uninitialized T[N]
        {% for name, index in names %}
          @channels[{{index}}] = {{name}}
        {% end %}
      end

      {% for name, index in names %}
        def {{name.id}}
          @channels[{{index}}]
        end

        def {{name.id}}=(value : T)
          @channels[{{index}}] = value
        end
      {% end %}

      {% for m, t in {u8: UInt8, u16: UInt16, u32: UInt32} %}
        def to_{{ m }}
          {% if t == @type.type_vars[0] %}
            self
          {% else %}
            {{@type.name(generic_args: false)}}({{t}}).new(@channels.map { |c| {{t}}.new((c / T::MAX) * {{t}}::MAX) })
          {% end %}
        end
      {% end %}

      def to_s(io : IO)
        io << {{@type.name}} << '(' << @channels.join(", ") << ')'
      end

      # Get the Euclidean distance between self and *other*
      def dist(other)
        Math.sqrt(@channels.map_with_index do |c, i|
          (other.channels[i].to_i32 - c.to_i32) ** 2
        end.sum)
      end
    end
  end
end

require "./colors/hsv"
require "./colors/rgb"
require "./colors/rgba"
require "./colors/gray"
require "./colors/gray_alpha"
