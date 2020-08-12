variable "project_id" {
  description = "Google project ID to use"
}

variable "label" {
  default = {
    namespace   = ""
    environment = ""
    stage       = ""
  }

  type = object({
    namespace   = string
    environment = string
    stage       = string
  })
}

variable "label_attributes" {
  description = "List of attributes to add to the labels resource"
  type        = list(string)
  default     = []
}

variable "kube_config" {
  type        = string
  description = "(Optional) Path to the kube config file. Defaults to ~/.kube/config"
  default     = null
}

variable "kube_context" {
  type        = string
  description = "(Optional) Context to choose from the config file. Can be sourced from KUBE_CTX"
  default     = null
}

variable "force_kube_context" {
  type        = bool
  description = "(Optional) If kube_context not defined force kube_context to match {project}-{stage}"
  default     = true
}

variable "kubernetes_namespaces" {
  description = "List of managed kubernetes namespaces"
  type        = list(map(any))
  default     = []
}

variable "kubernetes_default_labels" {
  description = "Lablels which are added to all managed Kubernetes resources"
  type        = map(string)
  default = {
    managed-by-terraform = true
  }
}

variable "kubernetes_default_annotations" {
  description = "Annotations which are added to all managed Kubernetes resources"
  type        = map(string)
  default     = {}
}

variable "google_service_accounts" {
  description = "List of managed google service accounts"
  type        = list(any)
  default     = []
}

variable "kubernetes_indentities" {
  description = "List of maps definitions for creating Kubernetes service accounts (able to run as GSA)"
  type        = any
  default     = []
}
