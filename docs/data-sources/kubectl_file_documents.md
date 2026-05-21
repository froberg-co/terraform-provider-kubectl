# Data Source: kubectl_file_documents

Splits a multi-document YAML string (separated by `---`) into individual documents that can be applied as separate `kubectl_manifest` resources.

## Example Usage

### With for_each (recommended)

Use the `manifests` attribute with `for_each` — adding or removing a document doesn't churn unrelated resources.

```hcl
data "kubectl_file_documents" "docs" {
    content = file("multi-doc-manifest.yaml")
}

resource "kubectl_manifest" "test" {
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}
```

### With count

`documents` exposes the raw list, indexable by position.

> Caveat: with `count`, reordering or inserting a document mid-list causes Terraform to destroy and recreate everything that shifts index — prefer `for_each` unless ordering is guaranteed.

```hcl
data "kubectl_file_documents" "docs" {
    content = file("multi-doc-manifest.yaml")
}

resource "kubectl_manifest" "test" {
    count     = length(data.kubectl_file_documents.docs.documents)
    yaml_body = element(data.kubectl_file_documents.docs.documents, count.index)
}
```

## Attribute Reference

* `manifests` - Map keyed by a stable document ID, valued by the document YAML. Best paired with `for_each`.
* `documents` - List of raw YAML documents. Best paired with `count` (see caveat above).
