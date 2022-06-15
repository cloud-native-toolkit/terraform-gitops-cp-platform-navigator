output "name" {
  description = "The name of the platform navigator instance"
  value       = local.instance_name
  depends_on  = [null_resource.setup_instance_gitops]
}

output "subscription_name" {
  description = "The name of the platform navigator operator"
  value       = local.subscription_name
  depends_on  = [null_resource.setup_instance_gitops]
}

output "namespace" {
  description = "The namespace where the platform navigator instance has been deployed"
  value       = local.namespace
  depends_on  = [null_resource.setup_instance_gitops]
}

output "subscription_namespace" {
  description = "The namespace where the platform navigator operator has been deployed"
  value       = var.subscription_namespace
  depends_on  = [null_resource.setup_instance_gitops]
}

output "branch" {
  description = "The branch where the module config has been placed"
  value       = local.application_branch
  depends_on  = [null_resource.setup_instance_gitops]
}

output "server_name" {
  description = "The server where the module will be deployed"
  value       = var.server_name
  depends_on  = [null_resource.setup_instance_gitops]
}

output "layer" {
  description = "The layer where the module is deployed"
  value       = local.layer
  depends_on  = [null_resource.setup_instance_gitops]
}

output "type" {
  description = "The type of module where the module is deployed"
  value       = local.type
  depends_on  = [null_resource.setup_instance_gitops]
}

output "subscription_type" {
  description = "The type of module where the module is deployed"
  value       = local.subscription_type
  depends_on  = [null_resource.setup_instance_gitops]
}
