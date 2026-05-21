# Apply using server-side apply (SSA) instead of the default client-side
# apply. Useful when many controllers share field ownership on the same
# object — `force_conflicts` lets us claim ownership of conflicting
# fields rather than failing the apply.

resource "kubectl_manifest" "test" {
  server_side_apply = true
  field_manager     = "terraform-kubectl"
  force_conflicts   = true

  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: name-here
data:
  greeting: "hello from server-side apply"
YAML
}
