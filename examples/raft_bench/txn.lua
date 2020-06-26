counter = 0

request = function()
   path = "/v1/txn"
   wrk.method = "PUT"
   wrk.body = "[ { \"KV\": { \"Verb\": \"set\", \"Key\": \"" .. counter .. "\", \"Value\": \"MQo=\"} } ]"
   counter = counter + 1
   return wrk.format(nil, path)
end
