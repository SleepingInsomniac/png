require "./spec_helper"

describe PNG do
  describe "#write" do
    it "generates the minimal 1x1 red pixel image" do
      output = IO::Memory.new
      PNG.write(output, 1, 1, Bytes[0xFF, 0x00, 0x00])

      output.rewind.to_slice.should eq(fixture("1x1_rgb.png"))
    end

    it "generates a 2x2 pixel image RGBA" do
      output = IO::Memory.new
      PNG.write(output, 2, 2, Bytes[
        0xFF, 0x00, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF,
        0x00, 0x00, 0xFF, 0xFF, 0x00, 0xFF, 0x00, 0xAA,
      ], PNG::Options.new(color_type: PNG::ColorType::TrueColorAlpha))

      output.rewind.to_slice.should eq(fixture("2x2_rgba.png"))
    end
  end
end
