# PNG

A simple PNG implementation in Crystal

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     png:
       github: sleepinginsomniac/png
   ```

2. Run `shards install`

## Usage

```crystal
require "png"

png = PNG.new(1, 1)
png[0, 0] = Bytes[0xFF, 0x00, 0x00]
png.write("1x1.png")
```

## Development

### Filter Types

- [x] None
- [ ] Sub
- [ ] Up
- [ ] Average
- [ ] Paeth

### Interlacing

- [x] None
- [ ] Adam7

## Contributing

1. Fork it (<https://github.com/sleepinginsomniac/png/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alex Clink](https://github.com/sleepinginsomniac) - creator and maintainer
