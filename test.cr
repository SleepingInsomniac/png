#!/usr/bin/env crystal

# ./download_pngsuite.sh
# crystal run test.cr -Dpng-debug

require "colorize"
require "./src/png"

def print_canvas(canvas)
  canvas.palette.try do |palette|
    puts "Palette:"
    n = 0
    palette.each_slice(3) do |(r, g, b)|
      print "██".colorize(r, g, b)
      puts if (n += 1) % 32 == 0
    end
    puts
  end

  puts "Canvas:"
  0u32.upto(canvas.height - 1) do |y|
    0u32.upto(canvas.width - 1) do |x|
      color = canvas.color(x, y).to_rgb8
      print "██".colorize(color.r, color.g, color.b)
    end
    puts
  end
end

start_time = Time.monotonic

Dir.glob("spec/fixtures/png-suite/*.png").sort.each do |path|
  next if File.basename(path).starts_with?('x')

  canvas = PNG.read(path)
  print_canvas(canvas)
  basename = File.basename(path)
  PNG.write("tmp/#{basename}", canvas)
  puts "✅ #{path}"
rescue e
  puts "❌ #{path} : #{e}"
end

puts Time.monotonic - start_time
