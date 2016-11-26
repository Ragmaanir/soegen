require "../src/soegen"

require "microtest"

# Use port 9500 because the setup and teardown methods
# delete all indices in the instance and that might be bad
# for some developers who got lots of data in their local instance
ES_PORT    = ENV.fetch("ES_PORT", "9500").to_i
INDEX_NAME = "soegen_test"

class Microtest::Test
  private def server
    @server.not_nil!
  end
end

Microtest.before do
  @server = Soegen::Server.new("localhost", ES_PORT, read_timeout: 1.second, connect_timeout: 1.second)
  # server.index("_all").delete
  idx = server.index(INDEX_NAME)
  idx.delete if idx.exists?
end

Microtest.after do
  # server.index("_all").delete
  idx = server.index(INDEX_NAME)
  idx.delete if idx.exists?
end

if !Soegen::Server.new("localhost", ES_PORT).up?
  raise "The test suite requires a running elasticsearch client on port #{ES_PORT}"
end

include Microtest::DSL
Microtest.run!
