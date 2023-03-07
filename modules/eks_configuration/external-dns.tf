data "aws_iam_policy_document" "external_dns_sts_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_oidc_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.eks_oidc_url, "https://", "")}"]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "external_dns" {
  assume_role_policy = data.aws_iam_policy_document.external_dns_sts_policy.json
  name               = "AmazonEKSExternalDNSControllerRole"
}

data "aws_iam_policy_document" "external_dns_iam_policy" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "external_dns" {
  name_prefix = "eks-external-dns"
  role        = aws_iam_role.external_dns.name
  policy      = data.aws_iam_policy_document.external_dns_iam_policy.json
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "external_dns" {
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "pods", "nodes", "endpoints"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["gateways", "virtualservices"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "external_dns" {
  metadata {
    name = "external-dns"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_dns.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_dns.metadata.0.name
    namespace = kubernetes_service_account.external_dns.metadata.0.namespace
  }
}

# resource "helm_release" "external_dns" {
#   name       = "external-dns"
#   namespace  = "kube-system"
#   wait       = true
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "external-dns"
#   version    = "4.6.0"

#   set {
#     name  = "rbac.create"
#     value = false
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = false
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = kubernetes_service_account.external_dns.metadata.0.name
#   }

#   set {
#     name  = "rbac.pspEnabled"
#     value = false
#   }

#   set {
#     name  = "name"
#     value = "external-dns"
#   }

#   set {
#     name  = "provider"
#     value = "aws"
#   }

#   set {
#     name  = "policy"
#     value = "sync"
#   }

#   set {
#     name  = "logLevel"
#     value = "warning"
#   }

#   set {
#     name  = "sources"
#     value = "{ingress,service}"
#   }

#   set {
#     name  = "domainFilters"
#     value = var.env == "prod" ? "{ ray.co }" : "{ ${terraform.workspace}.ray.co }"
#   }

#   set {
#     name  = "aws.zoneType"
#     value = "public"
#   }

#   set {
#     name  = "aws.region"
#     value = "us-east-1"
#   }
# }
