require "../spec_helper"

module SoegenTests
  class IndexTypeTest < Test
    def test_crud
      idx = server.index("test")
      t = idx.type("events")

      id = t.post({data: 1})

      assert id.size > 4

      t.put(id, {data: 2})

      assert t.get(id) == {"data" => 2}

      t.delete(id)

      assert t.get?(id) == nil
    end

    def test_get_raises
      idx = server.index("test")
      t = idx.type("events")
      t.get("1337")
    rescue Soegen::RequestError
      assert true
    else
      assert false
    end

    def test_exists
      idx = server.index("test")
      t = idx.type("events")
      assert !t.exists?
      t.post({data: 1})
      assert t.exists?
    end
  end
end
