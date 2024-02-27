module PNG
  struct PixelSize
    def self.parse(io : IO)
      x = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
      y = io.read_bytes(UInt32, IO::ByteFormat::BigEndian)
      meters = io.read_bytes(UInt8)
      new(x, y, meters > 0)
    end

    property x : UInt32 = 1u32
    property y : UInt32 = 1u32

    # When true, x and y represent how many pixels are in a meter.
    # When false, x and y represent the aspect ratio of a pixel
    property? meters : Bool = false

    def initialize(@x, @y, @meters = false)
    end

    def write(io : IO)
      io.write_bytes(@x, IO::ByteFormat::BigEndian)
      io.write_bytes(@y, IO::ByteFormat::BigEndian)
      io.write_byte(meters? ? 1u8 : 0u8)
    end
  end
end
