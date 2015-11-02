require "../spec_helper"

module SoegenTests
  class IndexTest < Minitest::Test
    def test_create_delete
      server = Soegen::Server.new
      idx = server.index("test")
      idx.delete
      assert !idx.exists?
      idx.create({} of String => JSON::Any)
      idx.refresh
      assert idx.exists?
    end
    
    def test_type
      server = Soegen::Server.new
      idx = server.index("test")
      events = idx.type("events")
    end

    def test_search
      server = Soegen::Server.new
      idx = server.index("test")

      idx.create({} of String => JSON::Any)
      events = idx.type("events")
      events.post(%[{"data": "some data"}])
      idx.refresh

      results = idx.search(%("query": {"match_all":{}}))

      assert results.total_count > 0
      assert !results.hits.empty?
    end
  end
end
