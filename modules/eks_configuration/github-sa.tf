resource "kubernetes_cluster_role" "github" {
  metadata {
    name = "github"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  # rule {
  #   api_groups = ["extensions", "networking.k8s.io"]
  #   resources  = ["ingresses"]
  #   verbs      = ["get", "list", "watch"]
  # }
  # rule {
  #   api_groups = ["networking.istio.io"]
  #   resources  = ["gateways", "virtualservices"]
  #   verbs      = ["get", "list", "watch"]
  # }
}

resource "kubernetes_cluster_role_binding" "github" {
  metadata {
    name = "github"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "User"
    name      = kubernetes_cluster_role.github.metadata.0.name
    api_group = "rbac.authorization.k8s.io"
  }
}
