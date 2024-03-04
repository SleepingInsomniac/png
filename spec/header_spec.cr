require "./spec_helper"

describe PNG::Header do
  describe "#colorize" do
    it "Converts bytes into a color struct at RGB 8bit" do
      header = PNG::Header.new(0, 0)
      color = header.colorize(Bytes[11, 22, 33])
      color.should be_a(PNG::RGB(UInt8))
    end

    it "Converts bytes into a color struct at RGB 16bit" do
      header = PNG::Header.new(0, 0, bit_depth: 16)
      color = header.colorize(Bytes[11, 11, 22, 22, 33, 33])
      color.should be_a(PNG::RGB(UInt16))
    end
  end
end
