module PNG
  module Filter
    def self.quantize(canvas, palette : Palette)
      new_canvas = Canvas.new(canvas.width, canvas.height, palette: palette.data)
      canvas.height.times do |y|
        canvas.width.times do |x|
          c = canvas.color(x, y).to_rgb8
          pc = palette.map_with_index { |v, i| {v, i} }.min_by { |pc| c.dist(pc[0]) }
          new_canvas[x, y] = pc[1]
        end
      end
      new_canvas
    end

    def self.grayscale(canvas)
      header = Header.new(canvas.width, canvas.height, color_type: ColorType::Grayscale)
      Canvas.make(header) do |x, y|
        canvas.color(x, y).to_g8
      end
    end
  end
end
