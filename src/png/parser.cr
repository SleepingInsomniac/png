module PNG
  class Parser
    PASSES = [
      {start_x: 0u32, start_y: 0u32, each_x: 8u32, each_y: 8u32},
      {start_x: 4u32, start_y: 0u32, each_x: 8u32, each_y: 8u32},
      {start_x: 0u32, start_y: 4u32, each_x: 4u32, each_y: 8u32},
      {start_x: 2u32, start_y: 0u32, each_x: 4u32, each_y: 4u32},
      {start_x: 0u32, start_y: 2u32, each_x: 2u32, each_y: 4u32},
      {start_x: 1u32, start_y: 0u32, each_x: 2u32, each_y: 2u32},
      {start_x: 0u32, start_y: 1u32, each_x: 1u32, each_y: 2u32},
    ]

    @header : Header

    property pass = 0
    property scanline = 0

    def initialize(@header)
    end

    def scanline_size
      case @header.interlacing
      when Interlacing::Adam7
        @header.bytes_per_row(row_pixels)
      else
        @header.bytes_per_row
      end
    end

    def next
      @scanline += 1
      return false if @header.interlacing.none?

      if @scanline == pass_rows
        while (@pass += 1) < PASSES.size
          pass = PASSES[@pass]
          break unless pass[:start_x] >= @header.width || pass[:start_y] >= @header.height
        end
        @scanline = 0
        true
      else
        false
      end
    end

    def y
      return @scanline if @header.interlacing.none?

      pass = PASSES[@pass]
      pass[:start_y] + (@scanline * pass[:each_y])
    end

    def x(n)
      return n if @header.interlacing.none?

      pass = PASSES[@pass]
      pass[:start_x] + (n * pass[:each_x])
    end

    def row_pixels
      case @header.interlacing
      when Interlacing::Adam7
        pass = PASSES[@pass]
        ((@header.width - pass[:start_x]) / pass[:each_x]).ceil.to_u32
      else
        @header.width
      end
    end

    def pass_rows
      pass = PASSES[@pass]
      ((@header.height - pass[:start_y]) + (pass[:each_y] - 1)) // pass[:each_y]
    end

    def row_bytes
      @header.bytes_per_row(row_pixels)
    end
  end
end
