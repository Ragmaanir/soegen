require "../spec_helper"

module SoegenTests
  class ServerTest < Minitest::Test
    def test_initialization
      server = Soegen::Server.new
      assert server.up?
    end

    def test_index
      server = Soegen::Server.new
      idx = server.index("test")
      assert idx
      assert idx.name == "test"
    end

    def test_search
      server = Soegen::Server.new

      idx = server.index("test")
      idx.create({} of String => JSON::Any)
      events = idx.type("events")
      events.post(%[{"data": "some data"}])
      idx.refresh

      results = server.search(%("query": {"match_all":{}}))

      assert results.total_count > 0
      assert !results.hits.empty?
    end

    def test_search_error
      server = Soegen::Server.new

      idx = server.index("not_real")
      idx.search(%("query": {"match_all":{}}))
    rescue Soegen::RequestError
      assert true
    else
      assert false
    end

    def test_stats
      server = Soegen::Server.new
      res = server.stats
      assert res.ok_ish?
    end

    def test_bulk
      skip
    end

    def is_up
      server = Soegen::Server.new
      assert server.up?
    end
  end
end
