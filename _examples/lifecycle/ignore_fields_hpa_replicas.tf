# Ignore drift on `spec.replicas` so a Horizontal Pod Autoscaler (or any
# other external controller) can manage the replica count without
# Terraform fighting it. This is the most common use of `ignore_fields`.

resource "kubectl_manifest" "test" {
  ignore_fields = ["spec.replicas"]

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
