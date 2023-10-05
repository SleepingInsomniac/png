module PNG
  class HeaderChunk < Chunk
    TYPE = "IHDR"
    @chunk_type = TYPE

    def self.read(io : IO)
      super do |io|
        width = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
        height = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
        bit_depth = io.read_bytes(UInt8)
        color_type = ColorType.new(io.read_bytes(UInt8))
        compression_method = Compression.new(io.read_bytes(UInt8)) # only accepted value is 0
        io.read_byte                                               # Filter type (Only accepted value is 0)
        interlacing = Interlacing.new(io.read_bytes(UInt8))
        options = Options.new(bit_depth, color_type, compression_method, interlacing)

        new(width, height, options)
      end
    end

    getter width : UInt32
    getter height : UInt32
    getter options : Options

    def initialize(@width, @height, @options)
    end

    # Writes a header chunk to the PNG file
    #
    def write(io : IO)
      super(io, 13) do |data|
        data.write_bytes(@width, IO::ByteFormat::BigEndian)  # Width
        data.write_bytes(@height, IO::ByteFormat::BigEndian) # Height
        data.write_byte(@options.bit_depth)
        data.write_byte(@options.color_type.value)
        data.write_byte(@options.compression_method.value) # Only zlib deflate (0)
        data.write_byte(0)                                 # Filter adaptive (only supported value)
        data.write_byte(@options.interlacing.value)        # None or Adam7
      end
    end
  end
end
