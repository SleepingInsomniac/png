require "digest/crc32"
require "digest/io_digest"

module PNG
  class Chunk
    class CRCMismatch < Error
    end

    def self.read(io : IO)
      byte_size = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
      crc_io = IO::Digest.new(io, Digest::CRC32.new, IO::Digest::DigestMode::Read)
      chunk_type_bytes = Bytes.new(4)
      crc_io.read_fully(chunk_type_bytes)
      chunk_type = String.new(chunk_type_bytes)
      sized_io = IO::Sized.new(crc_io, byte_size)

      begin
        yield chunk_type, sized_io, byte_size
      rescue e
        PNG.debug "Chunk read error: #{e}"
      end

      # Skip whatever was left over (ex: zlib adler32)
      crc_io.skip(sized_io.read_remaining)

      # Check the crc32
      crc32_expected = Bytes.new(4)
      io.read_fully(crc32_expected)
      crc32_calculated = crc_io.final

      if crc32_expected != crc32_calculated
        raise CRCMismatch.new("Crc32 mismatch - expected: #{crc32_expected}, actual: #{crc32_calculated}")
      end

      chunk_type
    end

    # Write a chunk to the PNG stream
    # Each chunk consists of
    # - Length of data (UInt32)
    # - Chunk type (String 4 chars)
    # - Data (Bytes)
    # - CRC32 chucksum (4 bytes)
    def self.write(chunk_type : String, io : IO, data : Bytes)
      io.write_bytes(data.size.to_u32, IO::ByteFormat::BigEndian)
      crc_io = IO::Digest.new(io, Digest::CRC32.new, IO::Digest::DigestMode::Write)
      crc_io << chunk_type
      crc_io.write(data)
      io.write(crc_io.final)
    end

    # :ditto:
    def self.write(chunk_type : String, io : IO, &block : IO -> Nil)
      size_pos = io.pos    # Remember the position of the size data
      io.write_bytes(0u32) # Write a temp 4 bytes to the size
      crc_io = IO::Digest.new(io, Digest::CRC32.new, IO::Digest::DigestMode::Write)
      crc_io << chunk_type
      data_pos = io.pos                 # Start counting data size from here
      yield crc_io                      # Write data
      size = (io.pos - data_pos).to_u32 # Calculate the size based on pos of data written
      io.seek(size_pos)                 # Seek back to the size location and write the value
      io.write_bytes(size, IO::ByteFormat::BigEndian)
      io.seek(0, IO::Seek::End) # Seek back to the end and write the crc
      io.write(crc_io.final)
    end

    # :ditto:
    def self.write(chunk_type : String, io : IO, size : UInt32, &block : IO -> Nil)
      io.write_bytes(size, IO::ByteFormat::BigEndian)
      crc_io = IO::Digest.new(io, Digest::CRC32.new, IO::Digest::DigestMode::Write)
      crc_io << chunk_type
      yield crc_io
      io.write(crc_io.final)
    end

    @chunk_type : String
    @data : Bytes

    def initialize(@chunk_type, io : IO::Sized)
      @data = Bytes.new(io.read_remaining)
      io.read(@data)
    end

    def write
      self.class.write(@chunk_type, IO::Memory.new(@data))
    end
  end
end
