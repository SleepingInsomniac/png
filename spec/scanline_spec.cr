require "./spec_helper"

describe PNG::Scanline do
  context "RGB / 8bit" do
    header = PNG::Header.new(3, 1)

    context "Filter method Sub" do
      filter_method = PNG::FilterMethod::Sub

      describe "#sub" do
        it "Filters the row by subtracting" do
          line = PNG::Scanline.new(header, filter_method, Bytes[0, 50, 100, 20, 60, 110, 25, 65, 115])
          io = IO::Memory.new
          line.sub { |byte| io.write_byte(byte) }
          io.to_slice.should eq(Bytes[0, 50, 100, 20, 10, 10, 5, 5, 5])
        end
      end

      describe "#unsub" do
        it "Unfilters the row by subtracting" do
          line = PNG::Scanline.new(header, filter_method, Bytes[0, 50, 100, 20, 10, 10, 5, 5, 5])
          line.unsub
          line.data.should eq(Bytes[0, 50, 100, 20, 60, 110, 25, 65, 115])
        end
      end
    end

    context "Filter method Up" do
      filter_method = PNG::FilterMethod::Sub

      describe "#up" do
        it "Filters the row by subtracting the previous" do
          previous = PNG::Scanline.new(header, filter_method, Bytes[1, 51, 101, 21, 61, 111, 26, 66, 116])
          line = PNG::Scanline.new(header, filter_method, Bytes[0, 50, 100, 20, 60, 110, 25, 65, 115])
          io = IO::Memory.new

          line.up(previous) do |byte|
            io.write_byte(byte)
          end

          io.to_slice.should eq(Bytes[255, 255, 255, 255, 255, 255, 255, 255, 255])
        end
      end
    end
  end

  describe "#set_pixel" do
    it "sets pixel values at 1-bit grayscale" do
      header = PNG::Header.new(3, 1, bit_depth: 1u8, color_type: PNG::ColorType::Grayscale)
      line = PNG::Scanline.new(header, PNG::FilterMethod::None, Bytes[0b0000_0000])
      line.set_pixel(0, Bytes[0b0000_0001])
      line.set_pixel(2, Bytes[0b0000_0001])

      line.data.should eq(Bytes[0b1010_0000])
    end

    it "sets pixel values at 2-bit grayscale" do
      header = PNG::Header.new(3, 1, bit_depth: 2u8, color_type: PNG::ColorType::Grayscale)
      line = PNG::Scanline.new(header, PNG::FilterMethod::None, Bytes[0b0000_0000])
      line.set_pixel(0, Bytes[0b0000_0011])
      line.set_pixel(2, Bytes[0b0000_0011])

      line.data.should eq(Bytes[0b1100_1100])
    end

    it "sets pixel values at 4-bit grayscale" do
      header = PNG::Header.new(3, 1, bit_depth: 4u8, color_type: PNG::ColorType::Grayscale)
      line = PNG::Scanline.new(header, PNG::FilterMethod::None, Bytes[0b0000_0000, 0b0000_0000])
      line.set_pixel(0, Bytes[0b0000_1111])
      line.set_pixel(2, Bytes[0b0000_1111])

      line.data.should eq(Bytes[0b1111_0000, 0b1111_0000])
    end
  end
end
