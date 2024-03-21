module Drawable
  # To be implemented by the including class
  abstract def width
  abstract def height
  abstract def set_color(x, y, color : Enumerable)
  abstract def color(x, y) : Enumerable

  # Iterate over each x, y coordinate and set the pixel value.
  def fill
    0.upto(height - 1) do |y|
      0.upto(width - 1) do |x|
        if color = yield(x, y)
          set_color(x, y, color)
        end
      end
    end
    self
  end

  def self.resize_nearest_neighbor(source : Drawable, dest : Drawable)
    width_ratio = source.width / dest.width
    height_ratio = source.height / dest.height

    dest.fill do |x, y|
      source.color(x * width_ratio, y * height_ratio)
    end
  end

  def self.resize_bilinear(source : Drawable, dest : Drawable)
    width_ratio = source.width / dest.width
    height_ratio = source.height / dest.height

    dest.fill do |x, y|
      dx = (x * width_ratio)
      dy = (y * height_ratio)

      x1, x2 = dx.floor, dx.ceil.clamp(0, source.width - 1)
      y1, y2 = dy.floor, dy.ceil.clamp(0, source.height - 1)

      tx = dx - x1
      ty = dy - y1

      c1 = source.color(x1, y1) # Top left
      c2 = source.color(x2, y1) # Top right
      c3 = source.color(x1, y2) # Bottom left
      c4 = source.color(x2, y2) # Bottom right

      c1.map_with_index do |v1, i|
        v2, v3, v4 = c2[i], c3[i], c4[i]
        (v1 * (1 - tx) * (1 - ty) +
          v2 * tx * (1 - ty) +
          v3 * (1 - tx) * ty +
          v4 * tx * ty).round
      end
    end
  end
end
