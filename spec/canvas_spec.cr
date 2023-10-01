require "./spec_helper"

describe PNG::Canvas do
  it "generates the minimal 1x1 red pixel image" do
    canvas = PNG::Canvas.new(1, 1)
    canvas[0, 0] = Bytes[0xFF, 0x00, 0x00]

    output = IO::Memory.new
    canvas.write(output)

    output.rewind.to_slice.should eq(fixture("1x1_rgb.png"))
  end
end
