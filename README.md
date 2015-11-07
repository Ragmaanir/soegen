# soegen

ElasticSearch client for crystal based on the Stretcher gem for ruby.

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

server = Soegen::Server.new # defaults to localhost:9200
idx = server.index("test")

assert !idx.exists?

idx.create

assert idx.exists?

t = idx.type("events")

t.post({data: "1337"})

idx.refresh

results = t.search({query: {match: {data: "1337"}}})

assert results.total_count == 1
assert results.hits.first["data"] == "1337"
```

## Contributing

1. Fork it ( https://github.com/ragmaanir/soegen/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Ragmaanir](https://github.com/ragmaanir) - creator, maintainer
