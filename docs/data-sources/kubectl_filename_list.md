# Data Source: kubectl_filename_list

Returns a list of files matching a glob pattern — useful for iterating over a directory of YAML manifests.

## Example Usage

```hcl
data "kubectl_filename_list" "manifests" {
    pattern = "./manifests/*.yaml"
}

resource "kubectl_manifest" "test" {
    count     = length(data.kubectl_filename_list.manifests.matches)
    yaml_body = file(element(data.kubectl_filename_list.manifests.matches, count.index))
}
```

## Attribute Reference

* `matches` - List of matching file names.
