module PNG
  def self.parse_PLTE(io : IO, byte_size)
    palette = Bytes.new(byte_size)
    io.read_fully(palette)
    raise Error.new("Palette not divisible by 3") if palette.size % 3 != 0
    PNG.debug "Palette contains #{palette.size // 3} entries"
    palette
  end
end
