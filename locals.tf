locals {
  kube_context       = var.force_kube_context ? module.label.id : var.kube_context
  sa_identity_prefix = "serviceAccount:${var.project_id}.svc.id.goog"

  google_service_account_defaults = {
    description  = ""
    display_name = ""
  }

  kubernetes_indentity_defaults = {
    email            = ""
    service_accounts = []
    labels           = {}
    annotations      = {}
  }

  ## ------ Google service accounts (normalized list of accounts created by this module)
  #
  google_service_accounts = [
    for sa in var.google_service_accounts : merge(
      local.google_service_account_defaults,
      {
        label_id = trimprefix(format("%s-%s", module.label.id, replace(sa.name, "/[[:punct:]]/", "-")), "-")
      },
    sa)
  ]

  ## ----- kubernetes_nampespaces computation
  #
  kubernetes_namespaces = [
    for ns in var.kubernetes_namespaces :
    merge(
      ns,
      {
        labels      = merge(var.kubernetes_default_labels, try(ns.labels, {}))
        annotations = merge(var.kubernetes_default_annotations, try(ns.annotations, {}))
      }
    )
  ]

  ## ------ Kubernetes service accounts
  #
  kubernetes_indentities = [
    for sa in var.kubernetes_indentities : merge(local.kubernetes_indentity_defaults, sa)
  ]

  kubernetes_service_accounts = flatten([
    for sa in local.kubernetes_indentities : [
      for ns_sa in sa.service_accounts : merge(sa,
        {
          name      = split("/", ns_sa)[1]
          namespace = split("/", ns_sa)[0]
          labels    = merge(var.kubernetes_default_labels, try(sa.labels, {}))
          annotations = merge(
            var.kubernetes_default_annotations,
            {
              "iam.gke.io/gcp-service-account" = try(
                google_service_account.gsa[sa.email].email,
                sa.email
              )
            }
          )
        }
    )]
  ])
}
