require "../header"

module PNG
  def self.parse_IHDR(io : IO)
    Header.new(
      width: io.read_bytes(UInt32, IO::ByteFormat::BigEndian),
      height: io.read_bytes(UInt32, IO::ByteFormat::BigEndian),
      bit_depth: io.read_bytes(UInt8),
      color_type: ColorType.new(io.read_bytes(UInt8)),
      compression_method: CompressionMethod.new(io.read_bytes(UInt8)),
      filter_type: FilterType.new(io.read_bytes(UInt8)),
      interlacing: Interlacing.new(io.read_bytes(UInt8))
    )
  end
end
