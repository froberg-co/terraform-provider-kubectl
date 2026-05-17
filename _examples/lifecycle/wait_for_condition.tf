# Wait on entries in `status.conditions[]` directly. Useful for kinds that
# report readiness through standard Kubernetes condition objects (e.g. Pod,
# Deployment, custom resources with conditions).

resource "kubectl_manifest" "deployment_available" {
  wait_for {
    condition {
      type   = "Available"
      status = "True"
    }
    condition {
      type   = "Progressing"
      status = "True"
    }
  }

  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 2
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
