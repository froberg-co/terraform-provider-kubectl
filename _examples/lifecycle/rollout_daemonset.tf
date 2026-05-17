# `wait_for_rollout` (true by default) now covers DaemonSet rollouts in
# addition to Deployment, StatefulSet, and APIService.

resource "kubectl_manifest" "test" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: name-here
spec:
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
