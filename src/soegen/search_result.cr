module Soegen
  class SearchResult

    class Internal
      JSON.mapping({
        "took" : Int32,
        "timed_out" : Bool,
        "_shards" : Shards,
        "hits" : Hits
      })
    end

    class Hits
      JSON.mapping({
        "total" : Int32,
        "max_score" : {type: Float64, nilable: true},
        "hits" : JSON::Any
      })
    end

    class Shards
      JSON.mapping({
        "total" : Int32,
        "successful" : Int32,
        "failed" : Int32
      })
    end

    def initialize(@response : CompletedRequest)
      @internal = Internal.from_json(@response.body)
    end

    def total_count
      @internal.hits.total
    end

    def none?
      !present?
    end

    def present?
      total_count > 0
    end

    def hits
      @internal.hits.hits as Array(JSON::Type)
    end

  end
end
