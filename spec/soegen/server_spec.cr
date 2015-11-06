require "../spec_helper"

module SoegenTests
  class ServerTest < Test
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
      skip
    end

    def is_up
      server = Soegen::Server.new("http://localhost:9000")
      assert !server.up?
      server = Soegen::Server.new("http://localhost:9200")
      assert server.up?
    end
  end
end
