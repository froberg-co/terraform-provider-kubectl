# Wait until a specific field on the live object matches an expected value,
# using gojsonq-style key paths. All `field` entries must be satisfied before
# the apply returns.

resource "kubectl_manifest" "pod_ready" {
  wait_for {
    field {
      key   = "status.phase"
      value = "Running"
    }
    field {
      key   = "status.podIP"
      value = "^(\\d+(\\.|$)){4}"
      value_type = "regex"
    }
  }

  yaml_body = <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.14.2
      readinessProbe:
        httpGet:
          path: "/"
          port: 80
        initialDelaySeconds: 10
YAML
}
