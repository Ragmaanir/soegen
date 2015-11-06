require "../src/soegen"

require "minitest"
require "power_assert"

class SoegenTests::Test < Minitest::Test
  private def server
    @server ||= Soegen::Server.new
  end

  def setup
    server.index("_all").delete
  end

  def teardown
    server.index("_all").delete
  end
end

if !Soegen::Server.new.up?
  raise "The test suite requires a running elasticsearch client on port 9200"
end

require "minitest/autorun"
