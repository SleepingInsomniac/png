module PNG
  # This is technically a bitmask: Alpha, Color, Palette
  # But it's easier to reprsent like this
  enum ColorType : UInt8
    Grayscale      = 0
    TrueColor      = 2
    Indexed        = 3
    GrayscaleAlpha = 4
    TrueColorAlpha = 6
  end

  enum FilterMethod : UInt8
    None    = 0
    Sub     = 1
    Up      = 2
    Average = 3
    Paeth   = 4
  end

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

module PNG
  def self.write(io : IO, width : UInt32, height : UInt32, data : Bytes, options : Options = Options.new)
    io.write(HEADER)
    HeaderChunk.new(width, height, options).write(io)
    DataChunk.new.write(io, data, options.bytes_per_pixel.to_u32 * width)
    EndChunk.new.write(io)
  end

  def self.write(path : String, width : UInt32, height : UInt32, data : Bytes, options : Options = Options.new)
    File.open(path, "wb") do |io|
      self.write(io, width, height, data, options)
    end
  end
end
