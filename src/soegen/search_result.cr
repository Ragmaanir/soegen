module Soegen
  class SearchResult
    # Internal class for parsing the elasticsearch search response body
    class Internal
      include JSON::Serializable

      getter took : Int32
      getter timed_out : Bool
      getter _shards : Shards
      getter hits : Hits
    end

    class Hits
      include JSON::Serializable

      getter total : HitEstimate
      getter max_score : Float64?
      getter hits : Array(Hit)
    end

    class HitEstimate
      include JSON::Serializable

      getter value : Int32
      getter relation : String
    end

    class Hit
      include JSON::Serializable

      getter _index : String
      getter _type : String
      getter _id : String
      getter _score : Float64
      getter _source : JSON::Any
    end

    class Shards
      include JSON::Serializable

      getter total : Int32
      getter successful : Int32
      getter failed : Int32
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
      total_count.value > 0
    end

    def raw_hits
      @internal.hits.hits
    end

    # returns just the hits of the search result as an array of hashes
    def hits
      raw_hits.map { |hit| hit._source.as_h }
    end

    # returns the complete elasticsearch result with all metadata as a hash
    def raw
      JSON.parse(@response.body).as_h
    end
  end
end
