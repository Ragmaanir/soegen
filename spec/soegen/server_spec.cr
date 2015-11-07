require "../spec_helper"

module SoegenTests
  class ServerTest < Test
    def test_initialization
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
      assert !server.client.ssl?
      # FIXME missing crystal api
      # assert server.client.read_timeout == 10.seconds
      # assert server.client.connect_timeout == 20.seconds

      assert !server.up?
    end

    def test_index
      idx = server.index("test")
      assert idx
      assert idx.name == "test"
    end

    def test_search
      idx = server.index("test")
      idx.create({} of String => JSON::Any)
      events = idx.type("events")
      events.post({data: "some data"})
      idx.refresh

      results = server.search({query: {match_all: {} of String => String}})

      assert results.total_count > 0
      assert !results.hits.empty?
    end

    def test_search_error
      idx = server.index("not_real")
      idx.search({query: {match_all: {} of String => String}})
    rescue Soegen::RequestError
      assert true
    else
      assert false
    end

    def test_stats
      res = server.stats
      assert res.ok_ish?
    end

    def test_bulk
      server.index("test").create
      server.bulk([
        {create: {_index: "test", _type: "event"}},
        {data: 9000},
        {create: {_index: "test", _type: "event"}},
        {data: 1337}
      ])

      server.refresh

      response = server.search({query: {match_all: {} of String => String}})
      assert response.total_count == 2
    end

    def is_up
      server = Soegen::Server.new("http://localhost:9000")
      assert !server.up?
      server = Soegen::Server.new("http://localhost:#{ES_PORT}")
      assert server.up?
    end
  end
end
