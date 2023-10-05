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

  describe "#read" do
    it "reads a minimal 1x1 red pixel PNG image" do
      io = IO::Memory.new(fixture("1x1_rgb.png"))
      png = PNG.read(io)
      png[:data].data.should eq(Bytes[0xFF, 0, 0])
    end

    it "checks the png header" do
      io = IO::Memory.new(Bytes[1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
      expect_raises(Exception) do
        PNG.read(io)
      end
    end
  end
end
