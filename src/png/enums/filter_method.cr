module PNG
  # Per scanline filtermethod
  #
  enum FilterMethod : UInt8
    None    = 0
    Sub     = 1
    Up      = 2
    Average = 3
    Paeth   = 4
  end
end
