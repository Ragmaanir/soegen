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
        "hits" : Array(Hit)
      })
    end

    class Hit
      JSON.mapping({
        "_index" : String,
        "_type" : String,
        "_id" : String,
        "_score" : Float64,
        "_source" :  JSON::Any
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

    def raw_hits
      @internal.hits.hits
    end

    def hits
      raw_hits.map{ |hit| hit._source as Hash(String, JSON::Type) }
    end

  end
end
