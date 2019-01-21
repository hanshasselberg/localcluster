# Local Consul Cluster

This tool spins up a local consul cluster for you with any number of servers and clients you might want.

## Usage

```
$ ./boot.sh -h
  -a path to config file for agents
  -d number of datacenters to spin up and wan-join together
  -e path to script to execute after the cluster is up, must be executable
  -h show this help
  -l log level (defaults to info)
  -m number of clients (defaults to 5)
  -n number of servers (defaults to 3)
  -p dc prefix (defaults to dc)
  -s path to config file for servers

Examples:
  `./boot.sh` # will boot 3 servers and 5 clients
  `./boot.sh -n 5 -m 20` # will boot 5 servers and 20 clients
  `./boot.sh -n 5 -m 20 -d 3` # will boot 5 servers and 20 clients each in dc1, dc2, and dc3 wan-joined together.
```
