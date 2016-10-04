require "../spec_helper"

describe Soegen::IndexType do
  test "crud" do
    idx = server.index(INDEX_NAME)
    t = idx.type("events")

    id = t.post({data: 1})

    assert id.size > 4

    t.put(id, {data: 2})

    assert t.get(id) == {"data" => 2}

    t.delete(id)

    assert t.get?(id) == nil
  end

  test "get raises" do
    begin
      idx = server.index(INDEX_NAME)
      t = idx.type("events")
      t.get("1337")
    rescue Soegen::RequestError
      assert true
    else
      assert false
    end
  end

  test "exists" do
    idx = server.index(INDEX_NAME)
    t = idx.type("events")
    assert !t.exists?
    t.post({data: 1})
    assert t.exists?
  end
end
