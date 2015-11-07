require "../src/soegen"

require "minitest"
require "power_assert"

ES_PORT = 9200

class SoegenTests::Test < Minitest::Test

  private def server
    @server.not_nil!
  end

  def setup
    @server = Soegen::Server.new("localhost", ES_PORT, read_timeout: 1.second, connect_timeout: 1.second)
    server.index("_all").delete
  end

  def teardown
    server.index("_all").delete
  end
end

if !Soegen::Server.new.up?
  raise "The test suite requires a running elasticsearch client on port #{ES_PORT}"
end

require "minitest/autorun"
