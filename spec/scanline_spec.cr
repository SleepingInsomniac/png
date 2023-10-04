require "./spec_helper"

describe PNG::Scanline do
  describe "#sub" do
    it "Filters the row by subtracting" do
      line = PNG::Scanline.new(Bytes[0, 50, 100, 20, 60, 110, 25, 65, 115], 3)
      io = IO::Memory.new

      line.sub do |byte|
        io.write_byte(byte)
      end

      io.to_slice.should eq(Bytes[0, 50, 100, 20, 10, 10, 5, 5, 5])
    end
  end

  describe "#up" do
    it "Filters the row by subtracting the previous" do
      previous = Bytes[1, 51, 101, 21, 61, 111, 26, 66, 116]
      line = PNG::Scanline.new(Bytes[0, 50, 100, 20, 60, 110, 25, 65, 115], 3)
      io = IO::Memory.new

      line.up(previous) do |byte|
        io.write_byte(byte)
      end

      io.to_slice.should eq(Bytes[255, 255, 255, 255, 255, 255, 255, 255, 255])
    end
  end
end
