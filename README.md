# soegen

ElasticSearch client for crystal based on the Stretcher gem for ruby.

## Compatibility

Tests pass with crystal 0.18.0 and ES 2.3.3.

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

For more documentation you can also look at the tests, they are pretty easy to understand.

## TODO

- [x] Indexes and IndexTypes: CRUD
- [x] Index documents
- [x] Index documents in bulk
- [x] Search for documents and return hit array
- [x] Log requests (as curl commands)
- [x] General callback for each request (for e.g. instrumentation)
- [ ] Analyzer API
- [ ] Alias API
- [ ] Tests for child documents

## Missing a feature? Found a bug? Need more documentation?

Please open an issue on this project.

## Contributing

1. Fork it ( https://github.com/ragmaanir/soegen/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Ragmaanir](https://github.com/ragmaanir) - creator, maintainer
