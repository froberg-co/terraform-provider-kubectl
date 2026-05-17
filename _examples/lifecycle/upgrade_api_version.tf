# Migrate a manifest between API versions in-place. Without this flag,
# changing `apiVersion` forces a delete+recreate (new UID). With it,
# the provider lets Kubernetes update the existing object via the new
# API surface (UID preserved).
#
# Typical use case: moving HorizontalPodAutoscaler from autoscaling/v1
# to autoscaling/v2 without losing the object.

resource "kubectl_manifest" "test" {
  upgrade_api_version = true

  yaml_body = <<YAML
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: name-here
spec:
  maxReplicas: 5
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: name-here
YAML
}
