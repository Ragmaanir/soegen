require "../src/soegen"

require "file_utils"
require "microtest"

# Use port 9500 because the setup and teardown methods
# delete all indices in the instance and that might be bad
# for some developers because they might lose data in their local instance
ES_PORT = ENV.fetch("ES_PORT", "9200").to_i
# ES_CMD      = ENV.fetch("SOEGEN_ES_CMD")
TRAVIS      = ENV.fetch("TRAVIS", "false") == "true"
SOEGEN_PATH = File.expand_path(Dir.current)
INDEX_NAME  = "soegen_test"
CID_FILE    = "temp/es.cid"

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

es_proc = nil

if !TRAVIS
  begin
    es_process = Process.new(
      "sudo",
      [
        "docker", "run",
        "-p", "#{ES_PORT}:#{ES_PORT}",
        "-e", "discovery.type=single-node",
        "--cidfile", CID_FILE,
        "docker.elastic.co/elasticsearch/elasticsearch:7.5.1",
      ],
      # output: STDOUT,
      error: STDOUT
    )

    wait_for("Timeout trying to reach elasticsearch on port #{ES_PORT}", tries: 20) do
      # raise "Elasticsearch terminated" if es_process.terminated?
      Soegen::Server.new("localhost", ES_PORT).up?
    end

    es_proc = es_process
  rescue
    puts "ERROR -> killing ES process"
    es_proc.try(&.terminate)
  end
end

Soegen::Server.new("localhost", ES_PORT).put("_template/test_template", body: {
  template: "soegen_*",
  settings: {
    number_of_shards:   1,
    number_of_replicas: 0,
  },
}.to_json)

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
  if es_proc
    cid = File.read(CID_FILE)
    Process.run("sudo", ["docker", "stop", cid])
    FileUtils.rm(CID_FILE)
  end
end

exit success ? 0 : -1
