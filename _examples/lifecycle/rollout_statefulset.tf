# `wait_for_rollout` (true by default) now covers StatefulSet rollouts in
# addition to Deployment, DaemonSet, and APIService.

resource "kubectl_manifest" "test" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: name-here
spec:
  serviceName: name-here
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
