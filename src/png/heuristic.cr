module PNG
  module Heuristic
    NONE    = ->(prev : Scanline?, curr : Scanline) { curr }
    SUB     = ->(prev : Scanline?, curr : Scanline) { curr.filter = FilterMethod::Sub; curr }
    UP      = ->(prev : Scanline?, curr : Scanline) { curr.filter = FilterMethod::Up; curr }
    AVERAGE = ->(prev : Scanline?, curr : Scanline) { curr.filter = FilterMethod::Average; curr }
    PAETH   = ->(prev : Scanline?, curr : Scanline) { curr.filter = FilterMethod::Paeth; curr }
    # TODO: minimum sum of absolute differences
  end
end
