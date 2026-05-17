---
page_title: "Install the CockroachDB operator via an ArgoCD ApplicationSet"
subcategory: "Guides"
description: |-
  Use kubectl_manifest to declare an ArgoCD ApplicationSet that installs
  the cockroach-operator Helm chart into a managed cluster.
---

# Install the CockroachDB operator via an ArgoCD ApplicationSet

This guide shows how to use `kubectl_manifest` to declare a single ArgoCD
[`ApplicationSet`](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/)
that fans out to one (or more) clusters and installs the
[`cockroach-operator`](https://github.com/cockroachdb/cockroach-operator)
Helm chart. The same pattern scales to many target clusters by switching
the generator from `list` to `cluster` or `git`.

## Prerequisites

The target cluster must already have:

- ArgoCD installed (so `argoproj.io/v1alpha1/ApplicationSet` and `Application` CRDs exist). See the [Install ArgoCD](./install-argocd.md) guide if you need the bootstrap.
- The `cluster` your ApplicationSet targets registered with ArgoCD as a managed cluster (`in-cluster` is the default registration for ArgoCD's own cluster).

A typical Terraform-only bootstrap orders the work as: install ArgoCD → declare ApplicationSets. Module those concerns separately so the destroy path stays clean.

## Terraform

```hcl
resource "kubectl_manifest" "cockroachdb_operator_appset" {
  # Skip client-side schema validation so this manifest applies even
  # when ArgoCD's CRDs were installed in the same run.
  validate_schema = false

  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cockroachdb-operator
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - list:
        elements:
          - cluster: in-cluster
            server: https://kubernetes.default.svc
            namespace: cockroach-operator
            chartVersion: "2.20.0"
  template:
    metadata:
      name: 'cockroach-operator-{{ "{{" }}.cluster{{ "}}" }}'
      labels:
        app.kubernetes.io/part-of: cockroachdb
    spec:
      project: default
      source:
        repoURL: https://cockroachdb.github.io/helm-charts/
        chart: cockroach-operator
        targetRevision: '{{ "{{" }}.chartVersion{{ "}}" }}'
        helm:
          releaseName: cockroach-operator
      destination:
        server: '{{ "{{" }}.server{{ "}}" }}'
        namespace: '{{ "{{" }}.namespace{{ "}}" }}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
YAML
}
```

## What this declares

- A single `ApplicationSet` in the `argocd` namespace.
- One generated `Application` per `list.elements` entry (here, just `in-cluster`). Extend the list to fan out across multiple clusters.
- Each generated `Application` installs the `cockroach-operator` Helm chart from `https://cockroachdb.github.io/helm-charts/` into the `cockroach-operator` namespace on the target cluster, creating the namespace if missing and using server-side apply.
- The CockroachDB CRDs (`CrdbCluster`, `CrdbNode`, etc.) become available once the operator pod is running, after which you can declare `CrdbCluster` instances as further `kubectl_manifest` resources.

## Targeting many clusters

Replace the `list` generator with a `cluster` generator to install the operator on every ArgoCD-registered cluster matching a label selector:

```yaml
generators:
  - clusters:
      selector:
        matchLabels:
          install-cockroach: "true"
      values:
        namespace: cockroach-operator
        chartVersion: "2.20.0"
```

The template body is unchanged — the cluster generator exposes `{{.name}}`, `{{.server}}`, and any `values` you set as template variables.

## Tearing it down

Destroying the `kubectl_manifest` deletes the `ApplicationSet`, which in turn deletes every generated `Application`. The Helm release is uninstalled and the operator namespace is cleaned up automatically thanks to `automated.prune`. If you want to keep clusters running after Terraform destroys, drop `automated.prune` and remove `CreateNamespace=true`.
