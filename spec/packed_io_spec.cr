require "./spec_helper"
require "../src/png/packed_io"

describe PNG::PackedIO do
  describe "#read" do
    it "reads 4bit sub byte values" do
      io = IO::Memory.new(Bytes[0xAB, 0xCD])
      packed_io = PNG::PackedIO.new(io, 4)

      packed_io.read_bytes(UInt8).to_s(16).should eq("a")
      packed_io.read_bytes(UInt8).to_s(16).should eq("b")
      packed_io.read_bytes(UInt8).to_s(16).should eq("c")
      packed_io.read_bytes(UInt8).to_s(16).should eq("d")
    end

    it "reads 2bit sub byte values" do
      io = IO::Memory.new(Bytes[0b11_01_10_00])
      packed_io = PNG::PackedIO.new(io, 2)

      packed_io.read_bytes(UInt8).to_s(2).should eq("11")
      packed_io.read_bytes(UInt8).to_s(2).should eq("1")
      packed_io.read_bytes(UInt8).to_s(2).should eq("10")
      packed_io.read_bytes(UInt8).to_s(2).should eq("0")
    end

    it "reads 1bit sub byte values" do
      io = IO::Memory.new(Bytes[0b1010_1010])
      packed_io = PNG::PackedIO.new(io, 1)

      4.times do
        packed_io.read_bytes(UInt8).to_s(2).should eq("1")
        packed_io.read_bytes(UInt8).to_s(2).should eq("0")
      end
    end

    it "reads into a buffer" do
      io = IO::Memory.new(Bytes[0b1010_1010])
      packed_io = PNG::PackedIO.new(io, 1)

      data = Bytes.new(8)
      packed_io.read_fully(data)

      data.should eq(Bytes[1, 0, 1, 0, 1, 0, 1, 0])
    end
  end

  describe "#write" do
    # it "writes into a buffer" do
    #   io = IO::Memory.new
    #   packed_io = PNG::PackedIO.new(io, 1)
    # end
  end
end
