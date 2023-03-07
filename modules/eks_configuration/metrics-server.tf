# resource "helm_release" "metrics_server" {
#   name       = "metrics-server"
#   namespace  = "kube-system"
#   wait       = true
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "metrics-server"
#   version    = "5.8.7"

#   set {
#     name  = "apiService.create"
#     value = "true"
#   }
# }
