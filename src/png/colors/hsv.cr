module PNG
  struct HSV < Color(Float64, 3)
    define_channels [h, s, v]
  end
end
