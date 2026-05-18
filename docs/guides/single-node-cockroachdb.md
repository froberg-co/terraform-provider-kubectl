---
page_title: "Run single-node CockroachDB on Kubernetes"
subcategory: "Guides"
description: |-
  Apply a single-node CockroachDB StatefulSet with kubectl_manifest —
  the simplest path to a working cockroach instance without installing
  the cockroach-operator.
---

# Run single-node CockroachDB on Kubernetes

This guide stands up a single CockroachDB pod via `kubectl_manifest` —
no Helm chart, no operator, no PVC. It's a small footprint for
development and demos. For production, see the
[Install the CockroachDB operator via an ArgoCD ApplicationSet](./argocd-cockroachdb-operator.md)
guide instead, which installs the operator and lets you declare
`CrdbCluster` resources for managed multi-node clusters.

## Caveats

- `--insecure` mode (no TLS, no auth) — fine for local development; never run this against a shared or production cluster.
- `emptyDir` volume — data is lost on every pod restart. Swap for a `PersistentVolumeClaim` if you need persistence.
- Single replica — no HA. Cockroach requires three replicas to tolerate node failure.
- The image (`cockroachdb/cockroach:v24.1.5`) is around 400 MB; first pull is slow on small clusters.

## Terraform

```hcl
resource "kubectl_manifest" "cockroach_dev" {
  # StatefulSet rollouts on small clusters (kind, etc.) can take longer
  # than the default rollout-wait window — skip the wait and let the
  # Pod come up in the background.
  wait_for_rollout = false

  yaml_body = <<YAML
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cockroach
  labels:
    app: cockroach
spec:
  serviceName: cockroach
  replicas: 1
  selector:
    matchLabels:
      app: cockroach
  template:
    metadata:
      labels:
        app: cockroach
    spec:
      containers:
        - name: cockroachdb
          image: cockroachdb/cockroach:v24.1.5
          imagePullPolicy: IfNotPresent
          command:
            - /cockroach/cockroach
            - start-single-node
            - --insecure
            - --advertise-host=$(POD_IP)
            - --http-addr=0.0.0.0:8080
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          ports:
            - name: sql
              containerPort: 26257
            - name: http
              containerPort: 8080
          volumeMounts:
            - name: data
              mountPath: /cockroach/cockroach-data
          readinessProbe:
            httpGet:
              path: /health?ready=1
              port: http
            initialDelaySeconds: 10
            periodSeconds: 5
          resources:
            requests:
              cpu: "100m"
              memory: "256Mi"
            limits:
              memory: "512Mi"
      volumes:
        - name: data
          emptyDir: {}
YAML
}
```

## Accompanying Service

The StatefulSet above won't be reachable from other pods until you front it with a Service. Add this in a second `kubectl_manifest` resource:

```hcl
resource "kubectl_manifest" "cockroach_dev_svc" {
  depends_on = [kubectl_manifest.cockroach_dev]

  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: cockroach
spec:
  clusterIP: None
  selector:
    app: cockroach
  ports:
    - name: sql
      port: 26257
      targetPort: sql
    - name: http
      port: 8080
      targetPort: http
YAML
}
```

A headless Service (`clusterIP: None`) gives every pod a stable DNS name (`cockroach-0.cockroach.<namespace>.svc.cluster.local`) which is what the `--advertise-host` mechanism above expects.

## Connecting

Once the pod reports `Ready`:

```sh
kubectl exec -it cockroach-0 -- /cockroach/cockroach sql --insecure
```

The web UI is on port 8080 — `kubectl port-forward cockroach-0 8080:8080` and visit <http://localhost:8080>.

## Tearing down

`terraform destroy` removes the Service and StatefulSet; the StatefulSet's pod terminates and any data in the emptyDir is gone with it.
