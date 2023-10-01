require "spec"
require "../src/png"

def fixture(name : String)
  buffer : Bytes? = nil

  File.open("spec/fixtures/" + name, "rb") do |file|
    buffer = Bytes.new(file.size)
    file.read_fully(buffer)
  end

  buffer.not_nil!
end
