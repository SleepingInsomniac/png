# PNG

A simple PNG implementation in Crystal

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     PNG:
       github: sleepinginsomniac/png
   ```

2. Run `shards install`

## Usage

```crystal
require "png"

PNG.write("1x1.png", 1, 1, Bytes[0xFF, 0, 0]) # writes a 1x1 single red pixel png
```

```crystal
require "png"

png = PNG.read("1x1.png")

png[:header]    # => PNG::HeaderChunk
png[:data]      # => PNG::DataChunk
png[:data].data # => Bytes(w * h * bpp)
```

___

#### Filters

| Filter  | read/write |
|---------|------------|
| None    | r/w        |
| Up      | r/w        |
| Average | r/w        |
| Paeth   | r/w        |

#### ColorTypes

All PNG color types are supported for reading / writing

| ColorType      | 1bit | 2bit | 4bit | 8bit | 16bit |
|----------------|------|------|------|------|-------|
| Grayscale      | r/w  | r/w  | r/w  | r/w  | r/w   |
| TrueColor      |      |      |      | r/w  | r/w   |
| Indexed        | -/-  | -/-  | -/-  | -/-  |       |
| GrayscaleAlpha |      |      |      | r/w  | r/w   |
| TrueColorAlpha |      |      |      | r/w  | r/w   |

#### Interlacing

| Name  |     |
|-------|-----|
| None  | r/w |
| Adam7 | -/- |


#### Not yet implemented
- Interpreting data at different bit depths. The data will be present as either Bytes or packed into Bytes
- Using per-row filters when encoding.
- Palette images

## Contributing

1. Fork it (<https://github.com/sleepinginsomniac/png/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alex Clink](https://github.com/sleepinginsomniac) - creator and maintainer
