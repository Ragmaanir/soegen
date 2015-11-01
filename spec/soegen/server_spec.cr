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
      idx.delete
      assert !idx.exists?
      idx.create({} of String => JSON::Any)
      assert idx.exists?
    end

    def test_search
      server = Soegen::Server.new
      results = server.search(%("query": {"match_all":{}}))

      assert results.total_count > 0
      assert !results.hits.empty?
    end
  end
end
