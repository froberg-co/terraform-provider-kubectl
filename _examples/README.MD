# Examples Directory

Every `.tf` file in this directory is exercised by the `TestAcckubectlYaml` acceptance test, which walks the tree, substitutes the literal string `name-here` with a unique random string, then runs a `plan` / `apply` / `refresh` / `plan` loop against a real Kubernetes cluster.

> Note: Each `.tf` file is tested in isolation — multi-file TF configurations are not supported. Each file must declare at least one `resource "kubectl_manifest" "test"` (the test framework checks this resource by name for existence/deletion); supporting `kubectl_manifest` resources may be declared alongside it in the same file (for example, when a CRD and an instance of it need to be installed together). Use `name-here` for the Kubernetes object name — the test framework substitutes this with a unique random string at run time.

## Basics

- [Create a basic Ingress](./ingress/basic_ingress.tf)
- [Create a basic service](./service/basic_service.tf)
- [Create a basic ConfigMap with multiple data entries](./configmap/multi_data.tf)
- [Create a Namespace](./namespaces/first-namespace.tf)
- [Create a ClusterRole](./roles/clusterrole.tf)
- [Dynamic Secret from variable](./secrets/dynamic_secret.tf)

## CRDs

- [Apply a Couchbase CRD instance](./crds/couchbase.tf)

## Lifecycle and apply options

- [`wait_for` with field matchers](./lifecycle/wait_for_field.tf) — wait on gojsonq paths into the live object.
- [`wait_for` with status conditions](./lifecycle/wait_for_condition.tf) — wait on `status.conditions[]` entries.
- [`wait_for_rollout` on DaemonSet](./lifecycle/rollout_daemonset.tf)
- [`wait_for_rollout` on StatefulSet](./lifecycle/rollout_statefulset.tf)
- [Skip rollout wait (`wait_for_rollout = false`)](./lifecycle/skip_rollout.tf)
- [Pin `delete_cascade`](./lifecycle/delete_cascade.tf) — Background vs Foreground.
- [In-place `apiVersion` migration (`upgrade_api_version`)](./lifecycle/upgrade_api_version.tf)
- [Ignore drift on `spec.replicas` (HPA pattern)](./lifecycle/ignore_fields_hpa_replicas.tf)
- [Server-side apply with `field_manager` + `force_conflicts`](./lifecycle/server_side_apply.tf)
- [Skip client-side schema validation](./lifecycle/validate_schema_off.tf)
- [Custom `sensitive_fields` on non-Secret manifests](./lifecycle/sensitive_fields.tf)

## Manifest splitting

The `manifests/` directory contains multi-document YAML files (used by `kubectl_path_documents` and `kubectl_file_documents` data source tests) rather than `.tf` files; see those data-source docs for usage.
