module PNG
  class Canvas
    getter width : UInt32
    getter height : UInt32
    @data : Bytes
    @options : Options

    def initialize(width : Int, height : Int, @options = Options.new)
      @width = width.to_u32
      @height = height.to_u32
      @data = Bytes.new(@width * @height * @options.bytes_per_pixel)
    end

    def index(x : Int, y : Int)
      ((@width * y) + x) * @options.bytes_per_pixel
    end

    def []=(x : Int, y : Int, value : Bytes)
      base_index = index(x, y)

      @options.bytes_per_pixel.times do |i|
        @data[base_index + i] = value[i]
      end
    end

    def [](x : Int, y : Int) : Bytes
      base_index = index(x, y)
      @data[base_index...(base_index + @options.bytes_per_pixel)]
    end

    def bytes : Bytes
      @data
    end

    def write(io : IO)
      io.write(HEADER)
      HeaderChunk.new(@width, @height, @options).write(io)
      DataChunk.new.write(io, @data, @options.bytes_per_pixel * @width)
      EndChunk.new.write(io)
    end

    def write(path : String)
      File.open(path, "wb") do |io|
        write(io)
      end
    end
  end
end
