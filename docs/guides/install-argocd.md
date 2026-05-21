---
page_title: "Install ArgoCD"
subcategory: "Guides"
description: |-
  Install ArgoCD into a Kubernetes cluster from its upstream YAML
  manifest using kubectl_path_documents and kubectl_manifest.
---

# Install ArgoCD

ArgoCD's upstream installer is a single multi-document YAML at
`https://raw.githubusercontent.com/argoproj/argo-cd/<version>/manifests/install.yaml`
(or `ha/install.yaml` for the high-availability layout). This guide
shows how to apply it idiomatically with this provider: pull the
manifest at plan time, split it into one document per resource, and
let Terraform manage the full set.

Pair this with the [ArgoCD ApplicationSet → CockroachDB Operator](./argocd-cockroachdb-operator.md) guide to bootstrap your cluster end-to-end (ArgoCD installs itself, then declaratively installs everything else).

## Pinning a version

Pin to a specific ArgoCD release tag — never `master` or `stable`.
Upgrades are then explicit `git diff`-able bumps rather than surprise
drift.

```hcl
variable "argocd_version" {
  type        = string
  description = "ArgoCD release tag (https://github.com/argoproj/argo-cd/releases)"
  default     = "v2.13.2"
}
```

## Namespace

```hcl
resource "kubectl_manifest" "argocd_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
YAML
}
```

## Applying the install manifest

Use the `http` data source to fetch the upstream install YAML, then
`kubectl_file_documents` to split it into individual documents and
`for_each` to manage each one as its own `kubectl_manifest`:

```hcl
data "http" "argocd_install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/${var.argocd_version}/manifests/install.yaml"
}

data "kubectl_file_documents" "argocd_install" {
  content = data.http.argocd_install.response_body
}

resource "kubectl_manifest" "argocd_install" {
  for_each = data.kubectl_file_documents.argocd_install.manifests

  override_namespace = "argocd"
  yaml_body          = each.value

  # Most ArgoCD CRDs and the StatefulSets they're consumed by are in
  # the same multi-doc file; skip client-side schema validation so the
  # documents apply regardless of the order Terraform picks.
  validate_schema = false

  depends_on = [kubectl_manifest.argocd_namespace]
}
```

> Why `override_namespace`? Some documents in the upstream YAML omit `metadata.namespace`. Setting `override_namespace = "argocd"` ensures every namespaced object lands in the right place without having to patch the manifest.

For the HA layout, swap the URL:

```
https://raw.githubusercontent.com/argoproj/argo-cd/${var.argocd_version}/manifests/ha/install.yaml
```

## Waiting for the rollout

The `argocd-server`, `argocd-repo-server`, `argocd-application-controller`, and `argocd-applicationset-controller` workloads all support the provider's default `wait_for_rollout` behaviour. You only need an explicit gate if you intend to apply `Application`/`ApplicationSet` resources in the same plan run — Terraform's resource graph plus `depends_on` handles ordering.

```hcl
resource "kubectl_manifest" "argocd_ready" {
  depends_on = [kubectl_manifest.argocd_install]

  wait_for {
    condition {
      type   = "Available"
      status = "True"
    }
  }

  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server
  namespace: argocd
YAML
}
```

This is a sentinel resource: it adopts the existing `argocd-server`
Deployment and blocks the plan until it reports `Available=True`.
Anything depending on this resource is guaranteed to see a working
ArgoCD API.

## Initial admin password

After install, ArgoCD writes a random admin password into the
`argocd-initial-admin-secret` Secret in the `argocd` namespace. Grab
it with `kubectl`:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

For a production install, replace this random password with one
managed in your secrets store and rotate via `kubectl_manifest` or
`argocd account update-password`.

## Exposing the UI

The default install leaves `argocd-server` reachable only inside the
cluster. The most common production options are:

- An **Ingress** with TLS termination at your existing controller — declare another `kubectl_manifest` with an `Ingress` pointing at the `argocd-server` service.
- The **gRPC + HTTP split** for `argocd` CLI clients: the upstream docs cover this at <https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/>.

## Tearing it down

Because every document is an individual `kubectl_manifest`, `terraform destroy` removes them one-by-one and the `Namespace` is the last to go (thanks to `depends_on`). The CRDs are owned resources too, so destroy cleanly cleans `Application`, `ApplicationSet`, and `AppProject` instances along with the controllers.

If you ever need a clean re-install after a botched apply, delete the namespace by hand — `kubectl delete ns argocd` — and re-run `terraform apply`.
