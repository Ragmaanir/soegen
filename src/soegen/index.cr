module Soegen
  # Represents an elasticsearch index and provides methods to get mapping (`#get_mapping`) and
  # settings (`#get_settings`) of the index as well as methods for `#create`ing/`#delete`ing
  # the index, checking whether it `#exists?` and for getting a handle to an `#index_type`.
  class Index < Component
    getter server : Server
    getter name : String

    def initialize(@server, @name)
    end

    def exists?
      request(:head).ok_ish?
    end

    def create
      create({} of String => String)
    end

    def create(options)
      request!(:put, "", {} of String => String, options.to_json)
    end

    def delete
      request!(:delete)
    end

    def get_mapping
      request!(:get, "_mapping")
    end

    def get_settings
      request!(:get, "_settings")
    end

    def refresh
      request!(:post, "_refresh")
    end

    def type(name : String)
      IndexType.new(self, name)
    end

    def uri_path(path : String) : String
      server.uri_path(join_path(name, path))
    end
  end
end
