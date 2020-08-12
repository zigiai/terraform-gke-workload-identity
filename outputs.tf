output "google_service_accounts" {
  description = "Managed gogole service accounts"
  value = { for name, sa in google_service_account.gsa : name =>
    tomap({
      id    = sa.id
      name  = sa.name
      email = sa.email
    })
  }
}

output "service_accounts_ids" {
  description = "Managed service accounts ids (namespace/serviceAccountName)"
  value       = keys(kubernetes_service_account.ksa)
}

output "mapped_indentities" {
  value = { for i in local.kubernetes_indentities :
    try(google_service_account.gsa[i.email].email, i.email) => i.service_accounts
  }
}
