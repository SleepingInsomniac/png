require "./spec_helper"
require "../src/png/packed_data"

describe PNG::PackedData do
  it "returns 1bit values packed into UInt8s" do
    pd = PNG::PackedData(UInt8).new(Bytes[0b1010_1010], 1)
    pd.to_a.should eq([1u8, 0u8, 1u8, 0u8, 1u8, 0u8, 1u8, 0u8])
  end

  it "returns 2bit values packed into UInt8s" do
    pd = PNG::PackedData(UInt8).new(Bytes[0b11001100], 2)
    pd.to_a.should eq([0b11u8, 0b00u8, 0b11u8, 0b00u8])
  end

  it "returns 4bit values packed into UInt8s" do
    pd = PNG::PackedData(UInt8).new(Bytes[0xAB, 0xCD], 4)
    pd.to_a.should eq([0xAu8, 0xBu8, 0xCu8, 0xDu8])
  end

  it "returns 8bit values" do
    pd = PNG::PackedData(UInt8).new(Bytes[0xAB, 0xCD], 8)
    pd.to_a.should eq([0xABu8, 0xCDu8])
  end

  it "returns a subset given a range" do
    pd = PNG::PackedData(UInt8).new(Bytes[0xAB, 0xCD], 4)
    pd[1..2].to_a.should eq([0xBu8, 0xCu8])
  end
end
