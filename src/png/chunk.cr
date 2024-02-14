require "digest/crc32"
require "digest/io_digest"

require "./enums/color_type"
require "./enums/compression_method"
require "./enums/filter_type"
require "./enums/interlacing"

module PNG
  module Chunk
    class CRCMismatch < Error
    end

    def self.read(io : IO, check_crc = true)
      byte_size = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
      crc_io = IO::Digest.new(io, Digest::CRC32.new, IO::Digest::DigestMode::Read)
      buffer = Bytes.new(4)
      crc_io.read_fully(buffer)
      chunk_type = String.new(buffer)

      PNG.debug " => Reading '#{chunk_type}' (#{byte_size} bytes)"

      start_pos = io.pos
      sized_io = IO::Sized.new(crc_io, byte_size)
      chunk = yield sized_io, byte_size, chunk_type
      end_pos = io.pos
      bytes_read = end_pos - start_pos

      # Skip whatever was left over (ex: zlib adler32)
      if bytes_read < byte_size
        PNG.debug "Skipping #{byte_size - bytes_read} bytes"
        crc_io.skip(byte_size - bytes_read)
      end

      if check_crc
        # Check the crc32
        crc32_expected = Bytes.new(4)
        io.read_fully(crc32_expected)
        crc32_calculated = crc_io.final

        if crc32_expected != crc32_calculated
          raise CRCMismatch.new("Crc32 mismatch - expected: #{crc32_expected}, actual: #{crc32_calculated}")
        end
      else
        io.skip(4) # Skip the crc32
      end

      chunk
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
  end
end
