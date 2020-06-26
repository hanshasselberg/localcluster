counter = 0

request = function()
   path = "/v1/kv/key" .. counter
   wrk.method = "PUT"
   wrk.body   = "value" .. counter
   wrk.headers["Content-Type"] = "application/x-www-form-urlencoded"

   counter = counter + 1
   return wrk.format(nil, path)
end
