class PNG
  struct HeaderChunk < Chunk
    @width : UInt32
    @height : UInt32
    @options : Options

    def initialize(@width, @height, @options)
      @chunk_type = "IHDR"
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
