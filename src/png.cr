require "./png/chunk"

class PNG
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

  struct Options
    property bit_depth : UInt8 # 1, 2, 4, 8, or 16
    property color_type : ColorType
    property compression_method : Compression # deflate is the only supported method
    property interlacing : Interlacing
    getter bytes_per_datum : UInt8

    def initialize(
      @bit_depth = 8u8,
      @color_type = ColorType::TrueColor,
      @compression_method = Compression::Deflate,
      @interlacing = Interlacing::None
    )
      bytes = case @color_type
              when ColorType::Grayscale      then 1u8
              when ColorType::TrueColor      then 3u8
              when ColorType::Indexed        then 1u8
              when ColorType::GrayscaleAlpha then 2u8
              when ColorType::TrueColorAlpha then 4u8
              else
                raise "Invalid color type #{@color_type}"
              end
      @bytes_per_datum = (bytes * @bit_depth) // 8u8
    end
  end

  # Instead of using an intermediate string, this is just the bytes
  # "\x89PNG\r\n\x1a\n"
  HEADER = Bytes[137, 80, 78, 71, 13, 10, 26, 10]

  property width : UInt32
  property height : UInt32
  property data : Bytes
  property options : Options

  def initialize(@width, @height, @data : Bytes, @options = Options.new)
  end

  def initialize(@width, @height, @options = Options.new)
    @data = Bytes.new(@width * @height * @options.bytes_per_datum)
  end

  # Set a value within the PNG
  #
  def []=(x : Int, y : Int, value : Bytes)
    index = ((@width * y) + x) * @options.bytes_per_datum
    value.each_with_index do |v, i|
      @data[index + i] = v
    end
  end

  # Write the png to IO
  #
  def write(io : IO)
    io.write(HEADER)
    HeaderChunk.new(@width, @height, @options).write(io)
    DataChunk.new.write(io, @data, @options.bytes_per_datum * @width)
    EndChunk.new.write(io)
  end

  # Create a file and write to the File IO
  #
  def write(path : String)
    File.open(path, "wb") do |io|
      write(io)
    end
  end
end
