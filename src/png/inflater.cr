require "digest/io_digest"
require "digest/crc32"
require "lib_z"

module PNG
  # Acts as a byte-by-byte inflater for IDAT payloads
  # Useful for decompressing as data is available.
  class Inflater
    private class TrimIO < IO::Memory
      # Trim out *bytes* from the beginning by copying *bytes*...size to the beginning
      # and reduce the size.
      def trim(bytes : Int)
        to_slice.copy_from(to_slice + bytes)
        seek(pos - bytes)
        @bytesize -= bytes
      end
    end

    class Error < Exception
      def initialize(msg : String)
        super(msg)
      end

      def initialize(ret, stream)
        msg = stream.msg
        msg = LibZ.zError(ret) if msg.null?

        if msg
          error_msg = String.new(msg)
          super("inflate: #{error_msg}")
        else
          super("inflate: #{ret}")
        end
      end
    end

    getter? ended = false

    def initialize
      @input = TrimIO.new
      @output = TrimIO.new
      @out_buffer = StaticArray(UInt8, 32).new(0u8)
      @stream = LibZ::ZStream.new
      @stream.zalloc = LibZ::AllocFunc.new { |opaque, items, size| GC.malloc(items * size) }
      @stream.zfree = LibZ::FreeFunc.new { |opaque, address| GC.free(address) }
      ret = LibZ.inflateInit2(pointerof(@stream), -LibZ::MAX_BITS, LibZ.zlibVersion, sizeof(LibZ::ZStream))
      raise Error.new(ret, @stream) unless ret.ok?
      @header_bytes = 0
    end

    def inhale(byte : UInt8)
      return if ended?

      if @header_bytes < 2
        @header_bytes += 1
        return
      end

      @input.write_byte(byte)

      while @input.size > 0
        @stream.avail_in = @input.size.to_u32
        @stream.next_in = @input.buffer

        @stream.avail_out = @out_buffer.size
        @stream.next_out = pointerof(@out_buffer).as(Pointer(UInt8))

        ret = LibZ.inflate(pointerof(@stream), LibZ::Flush::NO_FLUSH)
        case ret
        when .stream_end?                                                     then @ended = true
        when .buf_error?, .data_error?, .errno?, .mem_error?, .version_error? then raise Error.new(ret, @stream)
        when .need_dict?                                                      then raise Error.new("Predefined dict not supported")
        end

        input_bytes_read = @input.size - @stream.avail_in
        @input.trim(input_bytes_read)
        bytes_read = @out_buffer.size - @stream.avail_out
        break if bytes_read == 0

        bytes_read.times do |n|
          @output.write_byte(@out_buffer[n])
        end
      end
    end

    def read(slice : Bytes)
      return 0 if @output.size < slice.size

      @output.pos = 0
      @output.read(slice)
      @output.trim(slice.size)
      @output.seek(@output.size)
      slice.size
    end

    def bytes_available
      @output.size
    end
  end
end
