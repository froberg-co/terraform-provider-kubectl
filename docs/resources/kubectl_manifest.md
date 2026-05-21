# Resource: kubectl_manifest

Manages a Kubernetes object declared as raw YAML. Internally uses the same code path as `kubectl apply`: edit the `yaml_body` and the live object is updated in place, with full lifecycle (create / update / delete / drift detection) tracked by Terraform.

> **Tip:** one document per resource. For multi-document files use the [`kubectl_path_documents`](https://registry.terraform.io/providers/froberg-co/kubectl/latest/docs/data-sources/kubectl_path_documents) data source to split them into individual `kubectl_manifest` resources.

## Example Usage

```hcl
resource "kubectl_manifest" "test" {
    yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    azure/frontdoor: enabled
spec:
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: "Prefix"
        backend:
          serviceName: test
          servicePort: 80
YAML
}
```

> Note: rollout waits for `Deployment`, `DaemonSet`, `StatefulSet`, and `APIService` are enabled by default — see [Waiting for Rollout](#waiting-for-rollout) below.

### With explicit `wait_for`

The `wait_for` block blocks the apply until **every** declared `field` and `condition` entry is satisfied. At least one entry is required.

#### Field matchers (gojsonq paths)


```hcl
resource "kubectl_manifest" "test" {
  wait_for {
    field {
      key = "status.containerStatuses.[0].ready"
      value = "true"
    }
    field {
      key = "status.phase"
      value = "Running"
    }
    field {
      key = "status.podIP"
      value = "^(\\d+(\\.|$)){4}"
      value_type = "regex"
    }
  }
  yaml_body = <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    readinessProbe:
      httpGet:
        path: "/"
        port: 80
      initialDelaySeconds: 10
YAML
}
```

#### Status-condition matchers

```hcl
resource "kubectl_manifest" "test" {
  wait_for {
    condition {
      type   = "Ready"
      status = "True"
    }
    condition {
      type   = "ContainersReady"
      status = "True"
    }
  }
  yaml_body = <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
    - name: nginx
      image: nginx:1.14.2
YAML
}
```

`field` and `condition` blocks may be combined — the resource is considered ready only once **every** entry across both types is satisfied.

## Argument Reference

* `yaml_body` - Required. YAML to apply to kubernetes.
* `sensitive_fields` - Optional. List of fields (dot-syntax) which are sensitive and should be obfuscated in output. Defaults to `["data", "stringData"]` for `v1/Secret` manifests.
* `force_new` - Optional. Forces delete & create of resources if the `yaml_body` changes. Default `false`.
* `upgrade_api_version` - Optional. When `true`, changing the `apiVersion` in `yaml_body` updates the resource in-place rather than forcing a delete and recreate. Useful for migrating manifests across API versions (e.g. `autoscaling/v2beta1` → `autoscaling/v2`) without resource churn. Default `false`.
* `server_side_apply` - Optional. Allow using server-side-apply method. Default `false`.
* `field_manager` - Optional. Override the default field manager name. This is only relevant when using server-side apply. Default `kubectl`.
* `force_conflicts` - Optional. When using server-side apply, force conflicts on field-ownership disputes (equivalent to `kubectl apply --force-conflicts`). Default `false`.
* `apply_only` - Optional. When `true`, the resource never issues a delete against Kubernetes — Terraform removes it from state but the live object is left intact. Default `false`.
* `ignore_fields` - Optional. List of map fields to ignore when applying the manifest. See below for more details.
* `override_namespace` - Optional. Override the namespace to apply the kubernetes resource to, ignoring any declared namespace in the `yaml_body`.
* `validate_schema` - Optional. Setting to `false` will mimic `kubectl apply --validate=false` mode. Default `true`.
* `wait` - Optional. When `true`, block the delete operation until the API server confirms the resource is gone. Default `false`.
* `delete_cascade` - Optional. Cascade mode for delete operations. One of `"Background"` or `"Foreground"`. When unset, defaults to `Background` unless `wait` is enabled, in which case it defaults to `Foreground`. Set this explicitly to match `kubectl`'s behaviour.
* `wait_for_rollout` - Optional. When `true` (default), wait for the resource to finish rolling out before returning. Supported `kind`s are `Deployment`, `DaemonSet`, `StatefulSet`, and `APIService`.
* `wait_for`- Optional. If set, will wait until **all** `field` and/or `condition` entries are satisfied, or until timeout is reached (see [below for nested schema](#nestedblock--wait_for)). Field queries use [gojsonq](https://github.com/thedevsaddam/gojsonq) syntax against the live object; condition entries are matched against `status.conditions[]`.

### Nested schemas
<a id="nestedblock--wait_for"></a>
### Nested Schema for `wait_for`

At least one of the following must be provided:

- `field` (Block List) Condition criteria for a field (see [below for nested schema](#nestedblock--wait_for--field))
- `condition` (Block List) Status-condition criteria (see [below for nested schema](#nestedblock--wait_for--condition))

<a id="nestedblock--wait_for--field"></a>
### Nested Schema for `wait_for.field`

Required:

- `key` (String) Key which should be matched from resulting object
- `value` (String) Value to wait for

Optional:

- `value_type` (String) Value type. Can be either a `eq` (equivalent) or `regex`

<a id="nestedblock--wait_for--condition"></a>
### Nested Schema for `wait_for.condition`

Required:

- `type` (String) Type as expected from the resulting Condition object (e.g. `Ready`, `Available`, `Progressing`).
- `status` (String) Status to wait for in the resulting Condition object (typically `True`, `False`, or `Unknown`).

## Attribute Reference

* `yaml_body_parsed` - Sensitive. Obfuscated version of `yaml_body`, with `sensitive_fields` hidden. Marked sensitive so Secret/ConfigMap content is hidden in `terraform plan` output.
* `api_version` - Extracted API Version from `yaml_body`.
* `kind` - Extracted object kind from `yaml_body`.
* `name` - Extracted object name from `yaml_body`.
* `namespace` - Extracted object namespace from `yaml_body`.
* `uid` - Kubernetes unique identifier from last run.
* `live_uid` - Current uuid from Kubernetes.
* `yaml_incluster` - A fingerprint of the current yaml within Kubernetes.
* `live_manifest_incluster` - A fingerprint of the current manifest within Kubernetes.

## Sensitive Fields

`sensitive_fields` obfuscates the given fields in `terraform plan` output. For `v1/Secret` manifests the default is `["data", "stringData"]`; specify it explicitly to obfuscate fields on other kinds. Use dot-separator syntax for nested keys.

```hcl
resource "kubectl_manifest" "test" {
    sensitive_fields = [
        "metadata.annotations.my-secret-annotation"
    ]

    yaml_body = <<YAML
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  name: istio-sidecar-injector
  annotations:
    my-secret-annotation: "this is very secret"
webhooks:
  - clientConfig:
      caBundle: ""
YAML
}
```

> Note: only map values can be obfuscated individually. To hide a list (or a sub-list element), mark the parent key sensitive — the entire subtree will be redacted.

## Ignore Manifest Fields

`ignore_fields` skips drift detection on the listed keys — typically used when a controller (HPA, operator, mutating webhook) owns specific fields you don't want Terraform to fight.

The following fields are always ignored as control metadata:
  - `status`
  - `metadata.finalizers`
  - `metadata.initializers`
  - `metadata.ownerReferences`
  - `metadata.creationTimestamp`
  - `metadata.generation`
  - `metadata.resourceVersion`
  - `metadata.uid`
  - `metadata.annotations.kubectl.kubernetes.io/last-applied-configuration`

Paths use Terraform's flattened-map syntax — `.`-separated keys. For example, to ignore the `annotations` map entirely:

```hcl
resource "kubectl_manifest" "test" {
    yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: name-here
  namespace: default
  annotations:
    this.should.be.ignored: "true"
YAML

    ignore_fields = ["metadata.annotations"]
}
```

Array elements are addressed by position. To ignore the `caBundle` inside the first webhook of the manifest below, use `webhooks.0.clientConfig.caBundle`:

```hcl
resource "kubectl_manifest" "test" {
    yaml_body = <<YAML
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  name: istio-sidecar-injector
webhooks:
  - clientConfig:
      caBundle: ""
YAML

    ignore_fields = ["webhooks.0.clientConfig.caBundle"]
}
```

More examples can be found in the provider tests.

## Waiting for Rollout

By default, the apply blocks until the live object reaches a steady state for these kinds:

- `Deployment` — desired replicas are updated and available.
- `DaemonSet` — all desired pods are scheduled and ready.
- `StatefulSet` — the rolling update completes and replicas match the spec.
- `APIService` — the service reports as available.

Set `wait_for_rollout = false` to skip the wait.

## Import

Existing objects can be imported. The ID uses `//` as the separator (since `apiVersion` itself can contain `/`):

```
# Cluster-scoped object: <apiVersion>//<Kind>//<name>
terraform import kubectl_manifest.my-namespace v1//Namespace//my-namespace

# Namespaced object: <apiVersion>//<Kind>//<name>//<namespace>
terraform import kubectl_manifest.crd-example certmanager.k8s.io/v1alpha1//Issuer//cluster-selfsigned-issuer-root-ca//my-namespace
```
