es docker image aborts:

ERROR: [2] bootstrap checks failed
[1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
[2]: the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured

but only when started via Process.run/new

seems like the stupid -e param is not passed correctly ... why???
