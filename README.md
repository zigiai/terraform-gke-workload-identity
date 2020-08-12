# Managed Google and Kubernetes Service Accounts with WorkloadIdentity
###### tags: `zigiai` `terraform` `gke` `gcp` `workloadidentity` `kubernetes` `serviceaccount`

The module manages creation of GSAs and KSAs and provides mapping of KSA to GSA using GKE Workload Identity. It also manages creation of Kubernetes names for service accounts.

## Usage
### Create GSAs and KSAs and bind them using Workload Identity

Let's see the bellow example:

```hcl
module "identity" {
  source = "./"

  # label = {
  #   namespace = "myproj"
  #   stage = "test"
  #   environment = "dev"
  # }
  # label_attributes = [ "foo", "bar "]

  google_service_accounts = [
    { 
      name = "foo"
      display_name = "foo"
      description = "foo service account"
    },
    { name = "bar" },
    { name = "t1:secretmanager" }
  ]

  kubernetes_namespaces = [
    { name = "t1" },
    { name = "ns2" },
    { 
      name = "sqlproxy"
      annotations = {}
      labels = {}
    }
  ]

  kubernetes_indentities = [
    {
      email = "foo"
      service_accounts = [
        "t1/sva1",
        "ns2/sva2"
      ]
      labels      = {}
      annotations = {}
    }
  ]}
```

The above code creates several types of resources both in GCP and GKE. First of all it creates three GCP service accounts, then it creates three Kubernetes namespaces.
Apart from this it handles Kubernetes service accounts create namely `t1/sva1`, `ns2/sva2` (t1 and ns2 represent namespaces).

And the last but the most important things the module creates necessary IAM bindings and Kubernetes annotations for [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) to work.
These there variables provide the core functionality. Evidently all of them work together, so for example for `service_accounts` to work you should define `kubernetes_namespaces`, because you can't create a Kubernetes SA without having a namespace.

`kubernetes_identities.*.email` corresponds to a GCP service account. Module will first try to use the given value and lookup the email of the locally managed service accounts if it doesn't succeed it will treat the value as the actual GCP service account email.

Important notes:
- You can use punctuation in google service accounts names which actually respresent just a part of the generated service account names.
- You can use label to for GSA naming convention.
- Kubernetes service accounts have stable names as provided by the configuration.
