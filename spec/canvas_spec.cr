require "./spec_helper"

describe PNG::Canvas do
  it "crops to a new size" do
    canvas = PNG::Canvas.make(20, 20) do |x, y|
      v = (((y * 20 + x) / 400) * 255).to_u8
      n = (x + y) % 2 == 0 ? 255u8 : 0u8
      if (y > 4 && y < 15) && (x == 5 || x == 14) ||
         (x > 4 && x < 15) && (y == 5 || y == 14)
        {255u8 - v, v, n}
      else
        {n, 255u8 - v, v}
      end
    end
    print_canvas(canvas)
    print_canvas(canvas.crop(5, 5, 15, 15))
    print_canvas(canvas.crop(-5, -5, 26, 26))
  end
end
