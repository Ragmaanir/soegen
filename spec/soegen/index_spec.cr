require "../spec_helper"

module SoegenTests
  class IndexTest < Test
    def test_create_delete
      idx = server.index("test")
      assert !idx.exists?
      idx.create({} of String => JSON::Any)
      idx.refresh
      assert idx.exists?
    end

    def test_create_with_settings
      idx = server.index("test")
      idx.create({
        mappings: {
          mytype: {
            properties: {
              myfield: {type: "String"}
            }
          }
        }
      })
    end

    def test_type
      idx = server.index("test")
      events = idx.type("events")
    end

    def test_search
      time = Time.now.to_s
      idx = server.index("test")

      idx.create({} of String => JSON::Any)
      events = idx.type("events")
      events.post({data: time})
      idx.refresh

      results = idx.search({query: {match: {data: "invalid"}}})

      assert results.none?

      results = idx.search({query: {match: {data: time}}})

      assert results.total_count > 0
      assert !results.hits.empty?
      hit = results.hits.first as Hash(String, JSON::Type)
      source = hit["_source"] as Hash(String, JSON::Type)
      assert source["data"] == time
    end
  end
end
