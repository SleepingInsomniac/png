module PNG
  struct EndChunk
    # There is no data in an end chunk
    # - 4 bytes for size (0)
    # - IEND
    # - 4 bytes crc32
    def write(io : IO)
      io.write(Bytes[
        0x00, 0x00, 0x00, 0x00,
        0x49, 0x45, 0x4E, 0x44,
        0xAE, 0x42, 0x60, 0x82,
      ])
    end
  end
end
