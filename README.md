# soegen [![Build Status](https://travis-ci.org/Ragmaanir/soegen.svg?branch=master)](https://travis-ci.org/Ragmaanir/soegen)[![Dependency Status](https://shards.rocks/badge/github/ragmaanir/soegen/status.svg)](https://shards.rocks/github/ragmaanir/soegen)

ElasticSearch client for crystal based on the Stretcher gem for ruby.

### Version 0.12.0

## Compatibility

Tests pass with crystal 0.24.0 and ES 5.0.1.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  soegen:
    github: ragmaanir/soegen
    version: ~> 0.12.0
```

And then do:

```crystal
require "soegen"
```

## Usage

```crystal
require "../spec_helper"

describe Example do
  test "basic setup" do
    logger = Logger.new(STDOUT)
    server = Soegen::Server.new(
      host: "localhost",
      port: ES_PORT, # defaults to localhost:9200
      ssl: false,
      read_timeout: (0.5).seconds,
      connect_timeout: 1.seconds,
      logger: logger
    )

    assert server.up?
    assert server.client.host == "localhost"
    assert server.client.port == ES_PORT
    assert server.logger == logger
    assert !server.client.tls?

    idx = server.index(INDEX_NAME)

    assert !idx.exists?

    idx.create

    assert idx.exists?

    t = idx.type("events")

    t.post({data: "1337"})

    idx.refresh

    results = t.search({query: {match: {data: "1337"}}})

    assert results.total_count == 1
    assert results.hits.first["data"] == "1337"
  end

  test "generic request callback" do
    requests = [] of {req: Soegen::CompletedRequest, timing: Soegen::Timing}
    server.define_callback do |req, timing|
      requests << {req: req, timing: timing} # you could do your instrumentation here
    end

    server.up?
    server.index(INDEX_NAME).create

    assert requests.size == 2
    assert requests.all? { |pair| pair[:timing].duration < 1.second }

    up_request = requests[0][:req]

    assert up_request.method == "GET"
    assert up_request.path == "/"
    assert up_request.ok_ish?

    create_request = requests[1][:req]

    assert create_request.method == "PUT"
    assert create_request.path == INDEX_NAME
    assert create_request.ok_ish?
  end
end

```

## Testing

The ES configuration used in the tests is in `"./spec/config/`:

```yaml
cluster.name: es_soegen_5_0_0_test # avoid to join other clusters
cluster.routing.allocation.disk.watermark.low: 500mb
cluster.routing.allocation.disk.watermark.high: 200mb

node.name: main_test
node.max_local_storage_nodes: 1

http.port: ${ES_PORT}

gateway.recover_after_nodes: 1

discovery.zen.minimum_master_nodes: 1
discovery.zen.ping.unicast.hosts: []

path.logs: ${SOEGEN_PATH}/temp/elasticsearch/logs
path.data: ${SOEGEN_PATH}/temp/elasticsearch/data

```

Also the `spec_helper.cr` configures an index template to set the number of shards and replicas. To run the tests you have to provide your ES executable/command:

```bash
SOEGEN_ES_CMD=es5 crystal spec
```

It then automatically starts the server with the above config.

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
