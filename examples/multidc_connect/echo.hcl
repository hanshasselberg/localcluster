services {
  name = "echo"
  port = 9090
  connect {
    sidecar_service {}
  }
}

