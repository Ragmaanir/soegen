require "../src/soegen"

require "microtest"

# Use port 9500 because the setup and teardown methods
# delete all indices in the instance and that might be bad
# for some developers because they might lose data in their local instance
ES_PORT     = ENV.fetch("ES_PORT", "9500").to_i
ES_CMD      = ENV.fetch("SOEGEN_ES_CMD")
SOEGEN_PATH = File.expand_path(Dir.current)
INDEX_NAME  = "soegen_test"

# LOGGER     = Logger.new(File.new("log/test.log", "w"))
# LOGGER.level = Logger::DEBUG
# LOGGER.formatter = Soegen::Server::DEFAULT_LOG_FORMATTER

def self.wait_for(msg = "Timeout", tries = 5, &block : -> Bool)
  while (tries -= 1) >= 0
    return if block.call
    sleep 1
  end

  raise msg
end

env = {
  "SOEGEN_ES_CMD" => ES_CMD,
  "SOEGEN_PATH"   => SOEGEN_PATH,
  "ES_PORT"       => ES_PORT.to_s,
}

es_proc = nil

begin
  es_process = Process.new(ES_CMD, ["-Epath.conf=#{SOEGEN_PATH}/spec/config"], env: env, output: false, error: true)
  es_server = Soegen::Server.new("localhost", ES_PORT)

  wait_for("Timeout trying to reach elasticsearch on port #{ES_PORT}", tries: 10) do
    raise "Elasticsearch terminated" if es_process.terminated?
    es_server.up?
  end

  es_server.put("_template/test_template", body: {
    template: "soegen_*",
    settings: {
      number_of_shards:   1,
      number_of_replicas: 0,
    },
  }.to_json)

  es_proc = es_process
rescue
  es_proc.not_nil!.kill
end

class Microtest::Test
  private def server
    @server.not_nil!
  end
end

Microtest.before do
  @server = Soegen::Server.new("localhost", ES_PORT, read_timeout: 1.second, connect_timeout: 1.second)
  idx = server.index(INDEX_NAME)
  idx.delete if idx.exists?
end

Microtest.after do
  idx = server.index(INDEX_NAME)
  idx.delete if idx.exists?
end

include Microtest::DSL

begin
  success = Microtest.run
ensure
  es_proc.not_nil!.kill
end

exit success ? 0 : -1
