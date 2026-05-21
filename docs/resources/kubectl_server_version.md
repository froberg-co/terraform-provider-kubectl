# Resource: kubectl_server_version

Same as the [`kubectl_server_version` data source](../data-sources/kubectl_server_version.md), but exposed as a resource so it composes cleanly with `depends_on` and lifecycle hooks. Useful for pinning component versions (e.g. `kube-proxy`) to the cluster's exact server version.

## Example Usage

```hcl
resource "kubectl_server_version" "current" { }
```

## Argument Reference
  
* `triggers` - Optional. Map; any change forces a re-read of the server version. Same semantics as `null_resource.triggers`.

## Attribute Reference

* `version` - Version of the server, e.g. `v1.35.0`.
* `major` - Major version, semver if available, e.g. `1`.
* `minor` - Minor version, semver if available, e.g. `35`.
* `patch` - Patch version, semver if available, e.g. `0`.
* `git_version` - Version of the server, e.g. `v1.35.0-eks-aae39f`.
* `git_commit` - Git sha commit, e.g. `aae39f4697508697bf16c0de4a5687d464f4da81`.
* `build_date` - Date server binaries were built, e.g. `2026-04-22T08:19:12Z`.
* `platform` - Server platform name, e.g. `linux/amd64`.
