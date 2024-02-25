module PNG
  enum ColorType : UInt8
    Grayscale      = 0
    TrueColor      = 2
    Indexed        = 3
    GrayscaleAlpha = 4
    TrueColorAlpha = 6

    # Number of values required for the color type
    def channels
      case self
      when Grayscale, Indexed then 1_u8
      when GrayscaleAlpha     then 2_u8
      when TrueColor          then 3_u8
      when TrueColorAlpha     then 4_u8
      else
        raise Error.new("Invalid color type #{self}")
      end
    end
  end
end
