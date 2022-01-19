
variable "gitops_config" {
  type        = object({
    boostrap = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
    })
    infrastructure = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    services = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    applications = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
  })
  description = "Config information regarding the gitops repo structure"
}

variable "git_credentials" {
  type = list(object({
    repo = string
    url = string
    username = string
    token = string
  }))
  description = "The credentials for the gitops repo(s)"
  sensitive = true
}

variable "namespace" {
  type        = string
  description = "The namespace where the application should be deployed"
}

variable "subscription_namespace" {
  type        = string
  description = "The namespace where the application should be deployed"
  default     = "openshift-operators"
}

variable "server_name" {
  type        = string
  description = "The name of the server"
  default     = "default"
}

variable "channel" {
  type        = string
  description = "The channel from which the Platform Navigator should be installed"
  default     = "v5.0"
}

variable "instance_version" {
  type        = string
  description = "The version of the Platform Navigator should be installed"
  default     = "2020.4.1-eus"
}

variable "license" {
  type        = string
  description = "The license string that should be used for the instance"
  default     = "L-RJON-BUVMQX"
}

variable "catalog" {
  type        = string
  description = "The catalog source that should be used to deploy the operator"
  default     = "ibm-operator-catalog"
}

variable "catalog_namespace" {
  type        = string
  description = "The namespace where the catalog has been deployed"
  default     = "openshift-marketplace"
}

variable "replica_count" {
  type        = number
  description = "The number of replicas to create for the platform navigator"
  default     = 2
}
