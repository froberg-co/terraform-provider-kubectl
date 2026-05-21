# Submit a Deployment without blocking on rollout completion. Useful
# when the rolled-out state isn't a prerequisite for downstream
# Terraform resources, or when the workload's readiness can take longer
# than the default 10-minute rollout timeout.

resource "kubectl_manifest" "test" {
  wait_for_rollout = false

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
