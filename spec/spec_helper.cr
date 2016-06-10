require "../src/soegen"

require "microtest"

# Use port 9500 because the setup and teardown methods
# delete all indices in the instance and that might be bad
# for some developers who got lots of data in their local instance
ES_PORT = 9500

class Microtest::Test
  private def server
    @server.not_nil!
  end
end

Microtest.before do
  @server = Soegen::Server.new("localhost", ES_PORT, read_timeout: 1.second, connect_timeout: 1.second)
  server.index("_all").delete
end

Microtest.after do
  server.index("_all").delete
end

if !Soegen::Server.new("localhost", ES_PORT).up?
  raise "The test suite requires a running elasticsearch client on port #{ES_PORT}"
end

include Microtest::DSL
Microtest.run!
