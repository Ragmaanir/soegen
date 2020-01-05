module Soegen
  # Represents an elasticseach index-type and provides the related actions like
  # `#explain`, `#get`, `#update` and `#delete`.
  class IndexType < Component
    getter index : Index
    getter name : String

    # This helper class is used to parse the responses from elasticsearch
    class JsonDocument
      JSON.mapping({
        _id:      String,
        _index:   String,
        _type:    String,
        _version: Int32,
        _source:  {type: JSON::Any, nilable: true},
      })
    end

    def initialize(@index, @name)
    end

    def exists?
      request(:head, "").ok_ish?
    end

    def get?(id)
      response = request(:get, id)
      if response.ok_ish?
        JsonDocument.from_json(response.body)._source.not_nil!.as_h
      end
    end

    def get(id)
      response = request!(:get, id)
      JsonDocument.from_json(response.body)._source.not_nil!.as_h
    end

    def explain(id, query, options = {} of String => String)
      request!(:get, "#{id}/_explain", options, query)
    end

    def put(id, source, options = {} of String => String)
      request!(:put, id, options, source.to_json)
    end

    def post(source, *args)
      post(source.to_json, *args)
    end

    def post(source : String, options = {} of String => String)
      response = request!(:post, "", options, source)
      JsonDocument.from_json(response.body)._id
    end

    def update(id, body : String, options = {} of String => String)
      request!(:put, "id/_update", options, body)
    end

    def delete(id)
      request!(:delete, id)
    end

    def uri_path(path : String) : String
      index.uri_path(join_path(name, path))
    end

    def server : Server
      index.server
    end
  end
end
