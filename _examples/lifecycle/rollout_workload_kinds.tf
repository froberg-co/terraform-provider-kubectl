# wait_for_rollout (the default) now covers Deployment, DaemonSet,
# StatefulSet, and APIService. Setting it explicitly to true is
# redundant; setting it to false skips the wait.

resource "kubectl_manifest" "daemonset" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
        - name: fluentd
          image: fluent/fluentd:v1.16
YAML
}

resource "kubectl_manifest" "statefulset" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
spec:
  serviceName: redis
  replicas: 3
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis:7
YAML
}
