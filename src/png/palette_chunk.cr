class PNG
  struct PaletteChunk < Chunk
    def initialize
      @chunk_type = "PLTE"
    end
  end
end
