require "lib_z"

module PNG
  # Since IDAT boundaries could be anywhere in a stream, we need to be able to read data into an
  # input buffer and make the decompressed bytes available when there's enough input data
  class InflateStream < IO
    class Error < Exception
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
      @input = IO::Memory.new
      @stream = LibZ::ZStream.new
      @stream.zalloc = LibZ::AllocFunc.new { |opaque, items, size| GC.malloc(items * size) }
      @stream.zfree = LibZ::FreeFunc.new { |opaque, address| GC.free(address) }
      @stream.avail_in = 0u32
      @stream.next_in = @input.buffer

      ret = LibZ.inflateInit2(pointerof(@stream), -LibZ::MAX_BITS, LibZ.zlibVersion, sizeof(LibZ::ZStream))
      raise Error.new(ret, @stream) unless ret.ok?
    end

    def write(slice : Bytes) : Nil
      pos = @input.pos
      @input.write(slice)
      @input.pos = pos
      @stream.avail_in = @input.size.to_u32 - @input.pos
      @stream.next_in = @input.buffer + @input.pos
    end

    def read(slice : Bytes) : Int32
      return 0 if slice.empty?
      return 0 if ended?
      return 0 if @stream.avail_in == 0

      @stream.avail_out = slice.size.to_u32
      @stream.next_out = slice.to_unsafe

      start_avail_in = @stream.avail_in
      ret = LibZ.inflate(pointerof(@stream), LibZ::Flush::NO_FLUSH)
      bytes_read = slice.size - @stream.avail_out

      case ret
      when .stream_end?
        @ended = true
      when .buf_error?, .data_error?, .errno?, .mem_error?, .version_error?
        raise Error.new(ret, @stream)
      when .need_dict? then raise "Predefined dict not supported"
      end

      input_bytes_read = start_avail_in - @stream.avail_in
      @input.skip(input_bytes_read)
      @stream.avail_in = @input.size.to_u32 - @input.pos
      @stream.next_in = @input.buffer + @input.pos

      bytes_read
    end
  end
end
