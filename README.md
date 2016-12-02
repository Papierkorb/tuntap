# tuntap

Create TUN/TAP devices under Linux (And possibly others).  If you want to know
more about the intrinsics of TUN/TAP, read the kernel documentation over at
https://www.kernel.org/doc/Documentation/networking/tuntap.txt

**Important:** This shard may only run on Linux x86_64.  If you want to port
this to another platform let me know!

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  tuntap:
    github: Papierkorb/tuntap
```

## Usage

```crystal
require "tuntap"
```

Please see `samples/` for example programs.  Don't worry, they're documented :)

## Contributing

1. Fork it ( https://github.com/Papierkorb/tuntap/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Papierkorb](https://github.com/Papierkorb) Stefan Merettig - creator, maintainer
