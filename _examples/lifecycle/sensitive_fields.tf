# Hide arbitrary fields from Terraform plan output via `sensitive_fields`.
# Defaults to ["data", "stringData"] for v1/Secret manifests — set it
# explicitly to obfuscate fields on non-Secret kinds (e.g. ConfigMap
# entries holding tokens, MutatingWebhookConfiguration caBundles).

resource "kubectl_manifest" "test" {
  sensitive_fields = ["data.token"]

  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: name-here
data:
  greeting: "this value is visible in plan output"
  token: "and-this-one-is-obfuscated"
YAML
}
