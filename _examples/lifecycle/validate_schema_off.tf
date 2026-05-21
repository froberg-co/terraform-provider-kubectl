# Skip client-side schema validation. Equivalent to `kubectl apply
# --validate=false`. Useful when the manifest references a CRD whose
# OpenAPI schema isn't yet known to the cluster (e.g. installing a CRD
# and an instance of it in the same plan).

resource "kubectl_manifest" "test" {
  validate_schema = false

  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: name-here
data:
  note: "applied with validate_schema = false"
YAML
}
