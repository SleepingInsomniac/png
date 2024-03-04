require "../src/png"

canvas = PNG::Canvas.new(255, 255)
0u8.upto(canvas.height - 1) do |y|
  0u8.upto(canvas.width - 1) do |x|
    canvas[x, y] = {x, 255u8, y}
  end
end

PNG.write("examples/gradient.png", canvas)

canvas = PNG::Canvas.new(255, 255)

0.upto(canvas.height - 1) do |y|
  0.upto(canvas.width - 1) do |x|
    hue = (x / canvas.width) * 360.0
    value = 1 - (y / canvas.height)
    hsv = PNG::HSV.new(hue, 1.0, value)
    canvas[x, y] = PNG::RGB(UInt8).from_hsv(hsv)
  end
end

PNG.write("examples/test_pattern.png", canvas)

# 1-bit black and white
canvas = PNG::Canvas.new(PNG::Header.new(10, 10, bit_depth: 1, color_type: PNG::ColorType::Grayscale))
0.upto(canvas.height - 1) do |y|
  0.upto(canvas.width - 1) do |x|
    canvas[x, y] = {1u8} if (x + y) % 2 == 0
  end
end

PNG.write("examples/1bit_checker.png", canvas)
