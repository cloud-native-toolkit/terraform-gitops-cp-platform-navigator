module "gitops_module" {
   source = "./module"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  catalog = module.cp_catalogs.catalog_ibmoperators
  channel = module.cp4i-dependencies.platform_navigator.channel
  instance_version = module.cp4i-dependencies.platform_navigator.version
  license = module.cp4i-dependencies.platform_navigator.license
  entitlement_key = module.cp_catalogs.entitlement_key
  #kubeseal_cert = module.gitops.sealed_secrets_cert
  kubeseal_cert = module.cert.cert
  
  #Gowtham: Instance of the CP4i Platform navigator to be created in gitops-cp4i
  storageclass = "portworx-rwx-gp-sc"
}


