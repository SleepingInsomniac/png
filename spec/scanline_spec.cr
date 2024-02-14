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
end
