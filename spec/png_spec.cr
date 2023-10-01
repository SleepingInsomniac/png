require "./spec_helper"

describe PNG do
  it "generates the minimal 1x1 red pixel image" do
    png = PNG.new(1, 1)
    png[0, 0] = Bytes[0xFF, 0x00, 0x00]

    output = IO::Memory.new
    png.write(output)

    output.rewind.to_slice.should eq(fixture("1x1_rgb.png"))
  end

  it "generates a 2x2 pixel image RGBA" do
    png = PNG.new(2, 2, PNG::Options.new(color_type: PNG::ColorType::TrueColorAlpha))
    png[0, 0] = Bytes[0xFF, 0x00, 0x00, 0xFF]
    png[1, 0] = Bytes[0x00, 0xFF, 0x00, 0xFF]
    png[0, 1] = Bytes[0x00, 0x00, 0xFF, 0xFF]
    png[1, 1] = Bytes[0x00, 0xFF, 0x00, 0xAA]

    output = IO::Memory.new
    png.write(output)

    output.rewind.to_slice.should eq(fixture("2x2_rgba.png"))
  end
end
