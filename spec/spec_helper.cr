require "spec"
require "colorize"

require "../src/png"

def fixture(name : String)
  buffer : Bytes? = nil

  File.open("spec/fixtures/" + name, "rb") do |file|
    buffer = Bytes.new(file.size)
    file.read_fully(buffer)
  end

  buffer.not_nil!
end

def print_canvas(canvas)
  canvas.palette.try do |palette|
    n = 0
    palette.each_slice(3) do |(r, g, b)|
      print "██".colorize(r, g, b)
      puts if (n += 1) % 32 == 0
    end
    puts
  end

  0u32.upto(canvas.height - 1) do |y|
    0u32.upto(canvas.width - 1) do |x|
      color = canvas.color(x, y).to_rgb8
      print "██".colorize(color.r, color.g, color.b)
    end
    puts
  end
end
