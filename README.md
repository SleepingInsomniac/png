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

## TODO

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
