require "digest/crc32"
require "digest/io_digest"

class PNG
  abstract struct Chunk
    property chunk_type : String

    def initialize(@chunk_type)
    end

    # Write a chunk to the PNG stream
    # Each chunk consists of
    # - Length of data (UInt32)
    # - Chunk type (String 4 chars)
    # - Data (Bytes)
    # - CRC32 chucksum (4 bytes)
    def write(io : IO, data : Bytes)
      io.write_bytes(data.size.to_u32, IO::ByteFormat::BigEndian)
      crc_io = IO::Digest.new(io, Digest::CRC32.new, IO::Digest::DigestMode::Write)
      crc_io << @chunk_type
      crc_io.write(data)
      io.write(crc_io.final)
    end

    # :ditto:
    def write(io : IO, &block : IO -> Nil)
      size_pos = io.pos    # Remember the position of the size data
      io.write_bytes(0u32) # Write a temp 4 bytes to the size
      crc_io = IO::Digest.new(io, Digest::CRC32.new, IO::Digest::DigestMode::Write)
      crc_io << @chunk_type
      data_pos = io.pos                 # Start counting data size from here
      yield crc_io                      # Write data
      size = (io.pos - data_pos).to_u32 # Calculate the size based on pos of data written
      io.seek(size_pos)                 # Seek back to the size location and write the value
      io.write_bytes(size, IO::ByteFormat::BigEndian)
      io.seek(0, IO::Seek::End) # Seek back to the end and write the crc
      io.write(crc_io.final)
    end

    # :ditto:
    def write(io : IO, size : UInt32, &block : IO -> Nil)
      io.write_bytes(size, IO::ByteFormat::BigEndian)
      crc_io = IO::Digest.new(io, Digest::CRC32.new, IO::Digest::DigestMode::Write)
      crc_io << @chunk_type
      yield crc_io
      io.write(crc_io.final)
    end
  end
end

require "./header_chunk"
require "./data_chunk"
require "./end_chunk"
