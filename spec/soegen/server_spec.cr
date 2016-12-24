require "../spec_helper"

describe Soegen::Server do
  MATCH_ALL = {query: {match_all: {} of String => String}}

  test "initialization" do
    logger = Logger.new(STDOUT)
    server = Soegen::Server.new(
      "localhost",
      ES_PORT + 1,
      ssl: false,
      read_timeout: (0.5).seconds,
      connect_timeout: 1.seconds,
      logger: logger
    )

    assert server.client.host == "localhost"
    assert server.client.port == ES_PORT + 1
    assert server.logger == logger
    assert !server.client.tls?
    # FIXME missing crystal api
    # assert server.client.read_timeout == 10.seconds
    # assert server.client.connect_timeout == 20.seconds

    assert !server.up?
  end

  test "index" do
    idx = server.index(INDEX_NAME)
    assert idx
    assert idx.name == INDEX_NAME
  end

  test "search" do
    idx = server.index(INDEX_NAME)
    idx.create({} of String => JSON::Any)
    events = idx.type("events")
    events.post({data: "some data"})
    idx.refresh

    results = server.search(MATCH_ALL)

    assert results.total_count > 0
    assert !results.hits.empty?
  end

  test "search error" do
    begin
      idx = server.index("not_real")
      idx.search(MATCH_ALL)
    rescue Soegen::RequestError
      assert true
    else
      assert false
    end
  end

  test "stats" do
    res = server.stats
    assert res.ok_ish?
  end

  test "bulk" do
    server.index(INDEX_NAME).create
    server.bulk([
      {index: {_index: INDEX_NAME, _type: "event"}},
      {data: 9000},
      {index: {_index: INDEX_NAME, _type: "event"}},
      {data: 1337},
    ])

    server.refresh

    response = server.search(MATCH_ALL)
    assert response.total_count == 2
  end

  test "up?" do
    server = Soegen::Server.new("http://localhost:9000")
    assert !server.up?
    server = Soegen::Server.new("http://localhost:#{ES_PORT}")
    assert server.up?
  end

  test "callback" do
    i = 0
    server.request_callback do |req|
      i = i + 1
    end

    server.up?
    server.index(INDEX_NAME).create

    assert i == 2
  end

  test "callback error" do
    r = nil : Soegen::CompletedRequest?

    server.request_callback do |req|
      r = req
    end

    server.up?
    server.index(INDEX_NAME).search(MATCH_ALL) rescue nil

    assert r.not_nil!.status_code == 404
  end
end
