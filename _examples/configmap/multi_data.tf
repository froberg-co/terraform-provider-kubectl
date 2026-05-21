# A ConfigMap demonstrating both literal data entries and a multi-line
# config blob — the bread-and-butter use case for the provider.

resource "kubectl_manifest" "test" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: name-here
data:
  app.env: "production"
  log.level: "info"
  nginx.conf: |
    server {
      listen 8080;
      location / {
        return 200 "ok\n";
      }
    }
YAML
}
