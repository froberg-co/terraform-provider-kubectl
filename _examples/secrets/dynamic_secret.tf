locals {
  argocd_namespace = "default"
}

# variable "mock_data" {
#   default = {
#     "generic" = {
#       repo_url = "git@github.com/mock1/repo.git"
#       insecure = false
#       ssh_key_secret_name = "mock1-ssh-key"
#     }
#     "mock2" = {
#       repo_url = "https://github.com/mock2/repo.git"
#       insecure = true
#       ssh_key_secret_name = "mock2-ssh-key"
#     }
#   }
# }

resource "kubectl_manifest" "test" {
  sensitive_fields = ["stringData"]
  apply_only       = true
  force_new        = true

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    type       = "Opaque"
    metadata = {
      name      = "name-here-mock"
      namespace = local.argocd_namespace
      annotations = {
        "managed-by" : "argocd.argoproj.io"
        "argocd.argoproj.io/compare-options" : "IgnoreExtra"
        "argocd.argoproj.io/sync-options" : "Prune=false"
      }
      labels = {
        "argocd.argoproj.io/secret-type" : "repo-creds"
        "app.kubernetes.io/part-of" : "argocd"
        "app.kubernetes.io/name" : "argocd-secret"
      }
    }

    stringData = length(regexall("git@", "https://github.com/mock2/repo.git")) > 0 ? {
      name          = "mock2-repo"
      insecure      = tostring(true)
      sshPrivateKey = "mock-ssh-private-key"
      type          = "git"
      url           = "https://github.com/mock2/repo.git"
      } : {
      name     = "mock2-repo"
      insecure = tostring(true)
      username = "mock-username"
      password = "mock-password"
      type     = "git"
      url      = "https://github.com/mock2/repo.git"
    }
  })
}
