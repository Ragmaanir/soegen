# soegen

ElasticSearch client for crystal based on Stretcher gem for ruby.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  soegen:
    github: ragmaanir/soegen
```


## Usage


```crystal
require "soegen"

server = Soegen::Server.new
idx = server.index("test")

assert !idx.exists?

idx.create({} of String => JSON::Any)

assert idx.exists?

results = idx.search(%("query": {"match_all":{}}))

assert results.total_count == 0
```


TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/ragmaanir/soegen/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Ragmaanir](https://github.com/ragmaanir) - creator, maintainer
