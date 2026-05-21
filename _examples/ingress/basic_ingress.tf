# A minimal networking.k8s.io/v1 Ingress demonstrating path-based
# routing. Most clusters need an ingress controller (nginx, traefik,
# ALB, etc.) installed for the routing to actually take effect; the
# Ingress object itself applies regardless.

resource "kubectl_manifest" "test" {
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: name-here
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - http:
        paths:
          - path: /testpath
            pathType: Prefix
            backend:
              service:
                name: name-here
                port:
                  number: 80
YAML
}
