module PNG
  # In practice, the only compression method is deflate
  enum CompressionMethod : UInt8
    Deflate = 0
  end
end
