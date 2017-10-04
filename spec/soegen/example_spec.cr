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
