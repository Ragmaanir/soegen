# soegen [![Build Status](https://travis-ci.org/Ragmaanir/soegen.svg?branch=master)](https://travis-ci.org/Ragmaanir/soegen)[![Dependency Status](https://shards.rocks/badge/github/ragmaanir/soegen/status.svg)](https://shards.rocks/github/ragmaanir/soegen)

ElasticSearch client for crystal based on the Stretcher gem for ruby.

## Compatibility

Tests pass with crystal 0.23.1 and ES 5.0.1.

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

For more documentation you can also look at the tests, they are pretty easy to understand. E.g.:

```crystal
test "callback" do
    i = 0
    server.request_callback do |req|
      i = i + 1
    end

    server.up?
    server.index(INDEX_NAME).create

    assert i == 2
end
```

The request callback is invoked on every request with response and timing. So you can use that for instrumentation purposes.

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
