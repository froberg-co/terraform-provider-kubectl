resource "kubectl_manifest" "test" {
  apply_only    = false
  ignore_fields = ["metadata.labels"]
  yaml_body = yamlencode({
    apiVersion : "v1",
    kind : "Namespace",
    metadata : {
      name : "name-here",
      annotations : {
        "argocd.argoproj.io/sync-options" : "Prune=false"
      },
      labels : {
        "goldilocks.fairwinds.com/enabled" : "true"
      }
    }
  })
}