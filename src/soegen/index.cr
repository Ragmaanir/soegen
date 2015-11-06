module Soegen
  class Index < Component
    getter server, name

    def initialize(@server : Server, @name : String)
    end

    def exists?
      request(:head).ok_ish?
    end

    def create(options)
      request!(:put, "", {} of String => String, options.to_json)
    end

    def delete
      request!(:delete)
    end

    def refresh
      request!(:post, "_refresh")
    end

    def type(name : String)
      IndexType.new(self, name)
    end

    def uri_path(path : String)
      server.uri_path("#{name}/#{path}")
    end

  end
end
