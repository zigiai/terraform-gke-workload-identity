module "label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
  namespace   = var.label.namespace
  environment = var.label.environment
  stage       = var.label.stage
  attributes  = var.label_attributes
}

provider "kubernetes" {
  config_context = local.kube_context
  config_path    = var.kube_config
  version        = ">= 1.11.1"
}

provider "google" {
  version = "~> 3.23.0"
  project = var.project_id
}

provider "google-beta" {
  version = ">= 3.29.0,< 4.0.0"
  project = var.project_id
}

## Create kubernetes namespaces
#
resource "kubernetes_namespace" "ns" {
  for_each = { for ns in local.kubernetes_namespaces : ns.name => ns }

  metadata {
    name        = each.key
    labels      = each.value.labels
    annotations = each.value.annotations
  }
}

resource "random_string" "gsa_suffix" {
  for_each = { for sa in local.google_service_accounts : sa.name => sa }
  upper    = false
  lower    = true
  special  = false
  length   = 4
}

## Create google service accounts
#
resource "google_service_account" "gsa" {
  for_each    = { for sa in local.google_service_accounts : sa.name => sa }
  description = trimspace(join(" ", compact([each.value.description, "(Terraform managed)"])))

  account_id = trimprefix(format("%s-%s",
    substr(each.value.label_id, 0, min(25, length(each.value.label_id))),
    random_string.gsa_suffix[each.key].result
  ), "-")

  display_name = each.value.display_name
}

## Create kubernetes service accounts
#
resource "kubernetes_service_account" "ksa" {
  for_each = { for sa in local.kubernetes_service_accounts : "${sa.namespace}/${sa.name}" => sa }

  metadata {
    name        = each.value.name
    namespace   = each.value.namespace
    annotations = each.value.annotations
    labels      = each.value.labels
  }
}

## Bind Kubernetes SA to Google SA
#
resource "google_service_account_iam_member" "bind_workload_identity" {
  for_each = { for sa in local.kubernetes_service_accounts : "${sa.namespace}/${sa.name}" => sa }
  role     = "roles/iam.workloadIdentityUser"
  member   = "${local.sa_identity_prefix}[${each.value.namespace}/${each.value.name}]"

  service_account_id = try(
    google_service_account.gsa[each.value.email].name,
    format("projects/%s/serviceAccounts/%s",
      replace(each.value.email, "/(.*@)|(.iam.gserviceaccount.com)/", ""),
      each.value.email
    )
  )
}
