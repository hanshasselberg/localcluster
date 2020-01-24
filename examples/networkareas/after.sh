GREEN='\033[0;32m'
NC='\033[0m' # No Color

env CONSUL_HTTP_ADDR=127.0.0.1:8500 consul operator area create -peer-datacenter=dc2 -retry-join localhost:8102
env CONSUL_HTTP_ADDR=127.0.0.1:8501 consul operator area create -peer-datacenter=dc1 -retry-join localhost:8101

sleep 5
printf "${GREEN}network areas are healthy${NC}\n"
env CONSUL_HTTP_ADDR=127.0.0.1:8500 consul operator area members
env CONSUL_HTTP_ADDR=127.0.0.1:8501 consul operator area members

printf "${GREEN}kill s2.dc2 and leave s3.dc2${NC}\n"
ps -ef | grep 'dc2-s2' | awk '{ print $2 }' | xargs kill -9
env CONSUL_HTTP_ADDR=127.0.0.1:30108 consul leave

sleep 50
printf "${GREEN}s2.dc2 should be failed and s3.dc2 should be left${NC}\n"
env CONSUL_HTTP_ADDR=127.0.0.1:8500 consul operator area members | grep 's[23].dc2'

printf "${GREEN}restarting s2.dc2${NC}\n"
consul agent -ui -server -bootstrap-expect 3 -retry-join 127.0.0.1:8302 -data-dir dc2-s2 -bind 127.0.0.1 -node s2 -serf-lan-port 20107 -serf-wan-port 40107 -http-port 30107 -dns-port 50107 -server-port 10107 -log-level trace -config-file dummy.json -datacenter dc2 -domain consul >  /dev/null &

sleep 10
printf "${GREEN}s2.dc2 should be alive again${NC}\n"
env CONSUL_HTTP_ADDR=127.0.0.1:8500 consul operator area members | grep 's2.dc2'
