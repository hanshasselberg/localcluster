# Local Consul Cluster

This tool spins up a local consul cluster for you with any number of servers and clients you might want.

## Usage

```
./boot.sh -h
Usage: ./boot.sh OPTIONS
  -a path to config file for agents
  -d number of datacenters to spin up and wan-join together
  -e path to script to execute after the cluster is up, must be executable
  -h show this help
  -l log level (defaults to info)
  -m number of clients (defaults to 5)
  -n number of servers (leader is seperate, defaults to 2)
  -p dc prefix (defaults to dc)
  -s path to config file for servers

Examples:
  `./boot.sh` # will boot 1 leader, 2 servers and 5 clients
  `./boot.sh -n 4 -m 20` # will boot 1 leader, 4 servers and 20 clients
  `./boot.sh -n 4 -m 20 -d 3` # will boot 1 leader, 4 servers and 20 clients each in dc1, dc2, and dc3 wan-joined together.
```
