require "./spec_helper"

include PNG

describe Canvas do
  after_each { puts }

  it "sets a pixel 1bit grayscale" do
    canvas = Canvas.new(Header.new(2, 1, bit_depth: 1, color_type: ColorType::Grayscale))
    canvas[1, 0] = {0b1u8}
    print_canvas(canvas)
  end

  it "sets a pixel 2bit grayscale" do
    canvas = Canvas.new(Header.new(3, 1, bit_depth: 2, color_type: ColorType::Grayscale))
    canvas[1, 0] = {0b01u8}
    canvas[2, 0] = {0b11u8}
    print_canvas(canvas)
  end

  it "sets a pixel 4bit grayscale" do
    canvas = Canvas.new(Header.new(16, 1, bit_depth: 4, color_type: ColorType::Grayscale))
    0u8.upto(15u8) do |n|
      canvas[n, 0] = {n}
    end
    print_canvas(canvas)
  end

  it "sets a pixel 8bit grayscale" do
    canvas = Canvas.new(Header.new(16, 16, bit_depth: 8, color_type: ColorType::Grayscale))
    0.upto(15) do |y|
      0.upto(15) do |x|
        canvas[x, y] = {(y * 16 + x).to_u8}
      end
    end
    print_canvas(canvas)
  end

  it "sets a pixel 16bit grayscale" do
    canvas = Canvas.new(Header.new(32, 32, bit_depth: 16, color_type: ColorType::Grayscale))
    0.upto(31) do |y|
      0.upto(31) do |x|
        v = ((y * 32 + x) * 64).to_u16
        canvas[x, y] = {v}
      end
    end
    print_canvas(canvas)
  end

  describe "Resizing" do
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

    it "crops to a new size" do
      print_canvas(canvas.crop(5, 5, 15, 15))
      print_canvas(canvas.crop(-5, -5, 26, 26))
    end

    it "resizes with nearest neightbor" do
      print_canvas(canvas.resize_nearest_neighbor(35, 20))
      print_canvas(canvas.resize_nearest_neighbor(12, 12))
    end

    it "resizes with bilinear" do
      print_canvas(canvas.resize_bilinear(32, 32))
    end
  end
end
