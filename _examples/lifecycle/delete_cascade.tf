# Pin the Kubernetes deletion propagation policy explicitly. Without this
# field, the provider defaults to Background (kubectl's default) unless
# `wait = true`, in which case it switches to Foreground.
#
# - "Background": deletion returns immediately; dependents are cleaned up
#   asynchronously by the garbage collector.
# - "Foreground": the API server blocks until all dependents are deleted
#   before removing the parent.

resource "kubectl_manifest" "owner" {
  wait           = true
  delete_cascade = "Foreground"

  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.14.2
YAML
}
