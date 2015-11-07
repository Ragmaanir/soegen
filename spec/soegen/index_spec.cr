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
      config = {
        mappings: {
          mytype: {
            properties: {
              myfield: {type: "string"}
            }
          }
        }
      }
      idx.create(config)

      assert idx.get_mapping.body == {test: config}.to_json
    end

    def test_type
      idx = server.index("test")
      t = idx.type("events")
      assert t.name == "events"
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
      hit = results.hits.first
      assert hit["data"] == time
    end
  end
end
