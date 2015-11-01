module Soegen
  class IndexType
    getter index, name

    def initialize(@index : Index, @name : String)
    end

    def exists?
      request("head").ok_ish?
    end

    private def request(method : String, path = "" : String)
      path = "#{name}/#{path}"
      index.request(method, path)
    end
  end
end
