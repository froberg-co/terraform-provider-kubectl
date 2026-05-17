# Resource: kubectl_manifest

Create a Kubernetes resource using raw YAML manifests.

This resource handles creation, deletion and even updating your Kubernetes resources. This allows complete lifecycle management of your Kubernetes resources as terraform resources!

Behind the scenes, this provider uses the same capability as the `kubectl apply` command, that is, you can update the YAML inline and the resource will be updated in place in Kubernetes.

> **TIP:** This resource only supports a single yaml resource. If you have a list of documents in your yaml file,
> use the [kubectl_path_documents](https://registry.terraform.io/providers/froberg-co/kubectl/latest/docs/data-sources/kubectl_path_documents) data source to split the files into individual resources.

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

> Note: When the kind is a Deployment, this provider will wait for the deployment to be rolled out automatically for you!

### With explicit `wait_for`
If `wait_for` is specified, upon applying the resource, the provider will wait for **all** declared `field` and `condition` entries to be satisfied before proceeding. At least one `field` or `condition` block must be present.

#### Matching fields (gojsonq paths against the live object)


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

#### Matching `status.conditions[]` entries

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

`field` and `condition` blocks can be combined; the resource is considered ready only when **every** entry across both block types is satisfied.

## Argument Reference

* `yaml_body` - Required. YAML to apply to kubernetes.
* `sensitive_fields` - Optional. List of fields (dot-syntax) which are sensitive and should be obfuscated in output. Defaults to `["data"]` for Secrets.
* `force_new` - Optional. Forces delete & create of resources if the `yaml_body` changes. Default `false`.
* `upgrade_api_version` - Optional. When `true`, changing the `apiVersion` in `yaml_body` updates the resource in-place rather than forcing a delete and recreate. Useful for migrating manifests across API versions (e.g. `autoscaling/v2beta1` → `autoscaling/v2`) without resource churn. Default `false`.
* `server_side_apply` - Optional. Allow using server-side-apply method. Default `false`.
* `field_manager` - Optional. Override the default field manager name. This is only relevent when using server-side apply. Default `kubectl`.
* `force_conflicts` - Optional. Allow using force_conflicts. Default `false`.
* `apply_only` - Optional. It does not delete resource in any case Default `false`.
* `ignore_fields` - Optional. List of map fields to ignore when applying the manifest. See below for more details.
* `override_namespace` - Optional. Override the namespace to apply the kubernetes resource to, ignoring any declared namespace in the `yaml_body`.
* `validate_schema` - Optional. Setting to `false` will mimic `kubectl apply --validate=false` mode. Default `true`.
* `wait` - Optional. Set this flag to wait or not for finalized to complete for deleted objects. Default `false`.
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

* `yaml_body_parsed` - Obfuscated version of `yaml_body`, with `sensitive_fields` hidden.
* `api_version` - Extracted API Version from `yaml_body`.
* `kind` - Extracted object kind from `yaml_body`.
* `name` - Extracted object name from `yaml_body`.
* `namespace` - Extracted object namespace from `yaml_body`.
* `uid` - Kubernetes unique identifier from last run.
* `live_uid` - Current uuid from Kubernetes.
* `yaml_incluster` - A fingerprint of the current yaml within Kubernetes.
* `live_manifest_incluster` - A fingerprint of the current manifest within Kubernetes.

## Sensitive Fields

You can obfuscate fields in the diff output by setting the `sensitive_fields` option. This allows you to hide arbitrary field content by suppressing the information in the diff.

By default, this is set to `["data"]` for all `v1/Secret` manifests.

The fields provided should use dot-separator syntax to specify the field to obfuscate.

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

> Note: Only Map values are supported to be made sensitive. If you need to make a value from a list (or sub-list) sensitive, you can set the high-level key as sensitive to suppress the entire tree output.


## Ignore Manifest Fields

You can configure a list of yaml keys to ignore changes to via the `ignore_fields` field.
Set these for fields set by Operators or other processes in kubernetes and as such you don't want to update.

By default, the following control fields are ignored:
  - `status`
  - `metadata.finalizers`
  - `metadata.initializers`
  - `metadata.ownerReferences`
  - `metadata.creationTimestamp`
  - `metadata.generation`
  - `metadata.resourceVersion`
  - `metadata.uid`
  - `metadata.annotations.kubectl.kubernetes.io/last-applied-configuration`

These syntax matches the Terraform style flattened-map syntax, whereby keys are separated by `.` paths.

For example, to ignore the `annotations`, set the `ignore_fields` path to `metadata.annotations`:

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

For arrays, the syntax is indexed based on the element position. For example, to ignore the `caBundle` field in the
below manifest, would be: `webhooks.0.clientConfig.caBundle`

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

By default, this resource will wait for the following kinds to complete their rollout before proceeding:

- `Deployment` — wait until the desired number of replicas are updated and available.
- `DaemonSet` — wait until all desired pods are scheduled and ready.
- `StatefulSet` — wait until the rolling update completes and replicas match the spec.
- `APIService` — wait until the service is reported as available.

You can disable this behaviour by setting `wait_for_rollout = false` on the resource.

## Import

This provider supports importing existing resources. The ID format expected uses a double `//` as a deliminator (as apiVersion can have a forward-slash):

```
# Import the my-namespace Namespace
terraform import kubectl_manifest.my-namespace v1//Namespace//my-namespace

# Import the certmanager Issuer CRD named cluster-selfsigned-issuer-root-ca from the my-namespace namespace
$ terraform import -provider kubectl module.kubernetes.kubectl_manifest.crd-example certmanager.k8s.io/v1alpha1//Issuer//cluster-selfsigned-issuer-root-ca//my-namespace
```
