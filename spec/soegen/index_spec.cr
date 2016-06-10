require "../spec_helper"

describe Soegen::Index do
  def test_create_delete
    idx = server.index("test")
    assert !idx.exists?
    idx.create({} of String => JSON::Any)
    idx.refresh
    assert idx.exists?
  end

  test "create with settings" do
    idx = server.index("test")
    config = {
      mappings: {
        mytype: {
          properties: {
            myfield: {type: "string"},
          },
        },
      },
    }
    idx.create(config)

    assert idx.get_mapping.body == {test: config}.to_json
  end

  test "type" do
    idx = server.index("test")
    t = idx.type("events")
    assert t.name == "events"
  end

  test "search" do
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

    assert !results.raw.empty?
    ["took", "_shards", "hits"].each do |key|
      assert !results.raw[key].nil?
    end
  end
end
