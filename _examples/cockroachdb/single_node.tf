# Single-node CockroachDB run as a StatefulSet — the simplest path to
# get a working cockroach instance on Kubernetes without installing the
# cockroach-operator. The pod runs in `--insecure` mode against an
# emptyDir, so it loses state on restart; for production use, swap in a
# PVC and TLS certificates.
#
# `wait_for_rollout = false` because StatefulSet rollouts on small
# clusters (like kind) can take longer than a typical Terraform timeout.

resource "kubectl_manifest" "test" {
  wait_for_rollout = false

  yaml_body = <<YAML
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: name-here
  labels:
    app: name-here
spec:
  serviceName: name-here
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
