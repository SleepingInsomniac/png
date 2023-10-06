module PNG
  # This is technically a bitmask: Alpha, Color, Palette
  # But it's easier to reprsent like this
  enum ColorType : UInt8
    Grayscale      = 0
    TrueColor      = 2
    Indexed        = 3
    GrayscaleAlpha = 4
    TrueColorAlpha = 6

    # Number of values required for the color type
    def channels
      case self
      when Grayscale      then 1
      when TrueColor      then 3
      when Indexed        then 1
      when GrayscaleAlpha then 2
      when TrueColorAlpha then 4
      else
        raise "Invalid color type #{self}"
      end
    end
  end

  enum FilterMethod : UInt8
    None    = 0
    Sub     = 1
    Up      = 2
    Average = 3
    Paeth   = 4

    # This isn't an actual value in the PNG spec, but used to signify that the smallest resulting
    # filter should be used
    Adaptive
  end

  # In practice, the only compression method is deflate
  enum Compression : UInt8
    Deflate = 0
  end

  enum Interlacing : UInt8
    None  = 0
    Adam7 = 1
  end

  # Instead of using an intermediate string, this is just the bytes
  # "\x89PNG\r\n\x1a\n"
  HEADER = Bytes[137, 80, 78, 71, 13, 10, 26, 10]
end

require "./png/options"
require "./png/chunk"
require "./png/canvas"
require "./png/packed_io"

module PNG
  def self.write(io : IO, width : UInt32, height : UInt32, data : Bytes, options : Options = Options.new)
    io.write(HEADER)
    HeaderChunk.new(width, height, options).write(io)
    DataChunk.new(data, width, options.bits_per_pixel).write(io)
    EndChunk.new.write(io)
  end

  def self.write(path : String, width : UInt32, height : UInt32, data : Bytes, options : Options = Options.new)
    File.open(path, "wb") do |io|
      self.write(io, width, height, data, options)
    end
  end

  def self.read(io : IO)
    png_header = Bytes.new(8)
    io.read_fully(png_header)
    raise "PNG header mismatch" unless png_header == HEADER

    header_chunk = HeaderChunk.read(io)
    data = IO::Memory.new

    loop do
      chunk_type = Chunk.read(io) do |crc_io, byte_size, chunk_type|
        buffer = Bytes.new(byte_size)
        crc_io.read_fully(buffer)
        data.write(buffer) if chunk_type == "IDAT"
        chunk_type
      end

      break if chunk_type == EndChunk::TYPE
    end

    data_chunk = Compress::Zlib::Reader.open(data.rewind) do |inflate|
      DataChunk.unfilter(inflate, header_chunk.width, header_chunk.height, header_chunk.options.bits_per_pixel)
    end

    {header: header_chunk, data: data_chunk}
  end

  def self.read(path : String)
    File.open(path, "rb") do |io|
      self.read(io)
    end
  end
end
