# Wait on entries in `status.conditions[]` directly. Useful for kinds that
# report readiness through standard Kubernetes condition objects (e.g. Pod,
# Deployment, custom resources with conditions).

resource "kubectl_manifest" "test" {
  wait_for {
    condition {
      type   = "Available"
      status = "True"
    }
  }

  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: name-here
  labels:
    app: name-here
spec:
  replicas: 1
  selector:
    matchLabels:
      app: name-here
  template:
    metadata:
      labels:
        app: name-here
    spec:
      containers:
        - name: nginx
          image: nginx:1.14.2
YAML
}
