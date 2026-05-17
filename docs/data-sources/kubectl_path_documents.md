# Data Source: kubectl_path_documents

Loads every file matching a glob, splits each one into individual YAML documents, and (optionally) renders Terraform-style templating against the documents. Equivalent to `kubectl_filename_list` + `kubectl_file_documents` in a single step.

## Example Usage

### With for_each (recommended)

Use `manifests` with `for_each` so adding or removing a document doesn't churn unrelated resources.

```hcl
data "kubectl_path_documents" "manifests-directory-yaml" {
  pattern = "./manifests/*.yaml"
}
resource "kubectl_manifest" "directory-yaml" {
  for_each  = data.kubectl_path_documents.manifests-directory-yaml.manifests
  yaml_body = each.value
}
```

### With count

`documents` exposes the raw list, indexable by position.

> Caveat: reordering or inserting a document mid-list causes Terraform to destroy and recreate everything that shifts index — prefer `for_each` unless ordering is stable.

```hcl
data "kubectl_path_documents" "docs" {
    pattern = "./manifests/*.yaml"
}

resource "kubectl_manifest" "test" {
    count     = length(data.kubectl_path_documents.docs.documents)
    yaml_body = element(data.kubectl_path_documents.docs.documents, count.index)
}
```

### Templating

`vars` is substituted into each document before YAML parsing. Manifest:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
    - name: nginx
      image: ${docker_image}
      ports:
        - containerPort: 80
```

Terraform:

```hcl
data "kubectl_path_documents" "manifests" {
  pattern = "./manifests/*.yaml"
  vars = {
    docker_image = "https://myregistry.example.com/nginx"
  }
}
```

### Templating with directives

Templates support full Terraform template directives (`%{ if }`, `%{ for }`, etc.) for conditionals and loops:

Conditional example — defaults `image` when `docker_image` is empty:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
    - name: nginx
      image: %{ if docker_image != "" }${docker_image}%{ else }default-nginx%{ endif }
      ports:
        - containerPort: 80
```

```hcl
data "kubectl_path_documents" "manifests" {
  pattern = "./manifests/*.yaml"
  vars = {
    docker_image = ""
  }
}
```

### Templating with loops

A `%{ for }` directive plus YAML's `---` separator can produce one document per item — useful for fanning a manifest across namespaces:

Template:

```yaml
%{ for namespace in split(",", namespaces) }
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: myvolume-claim
  namespace: ${namespace}
spec:
  accessModes:
    - ReadWriteMany
  volumeMode: Filesystem
  resources:
    requests:
      storage: 100Gi
%{ endfor }
```

```hcl
data "kubectl_path_documents" "manifests" {
  pattern = "./manifests/*.yaml"
  vars = {
    namespaces = "dev,test,prod"
  }
}
```

With `namespaces = "dev,test,prod"` this produces three PVC documents, one per namespace.

## Argument Reference

* `pattern` - Required. Glob to match files on disk.
* `vars` - Optional. String→string map substituted into each document before YAML parsing.
* `sensitive_vars` - Optional. Same as `vars` but values are marked sensitive in plan output. Merged with `vars`.
* `disable_template` - Optional. When `true`, skip template parsing entirely and load documents verbatim.

## Attribute Reference

* `manifests` - Map keyed by a stable document ID, valued by the document YAML. Best paired with `for_each`.
* `documents` - List of YAML documents. Best paired with `count` (see caveat above).
