locals {
  base_name     = "ibm-platform-navigator"
  subscription_name = "${local.base_name}-operator"
  instance_name = "${local.base_name}-instance"
  bin_dir       = module.setup_clis.bin_dir
  subscription_chart_dir = "${path.module}/charts/ibm-platform-navigator-operator"
  subscription_yaml_dir = "${path.cwd}/.tmp/${local.base_name}/chart/${local.subscription_name}"
  //subscription_yaml_dir = "${path.cwd}/.tmp/ibm-platform-navigator/chart/ibm-platform-navigator-operator"
  instance_chart_dir = "${path.module}/charts/ibm-platform-navigator-instance"
  instance_yaml_dir     = "${path.cwd}/.tmp/${local.base_name}/chart/${local.instance_name}"
  //instance_yaml_dir     = "${path.cwd}/.tmp/ibm-platform-navigator/chart/ibm-platform-navigator-instance"

  subscription_values_content = {
    "ibm_platform_navigator_operator" = { 
      name="ibm-integration-platform-navigator"
      subscription = {
        channel=var.channel
        installPlanApproval="Automatic"
        name="ibm-integration-platform-navigator"
        source="ibm-operator-catalog"
        sourceNamespace="openshift-marketplace"
    }
   }
  }


  instance_values_content = {
    "ibm_platform_navigator_instance" = {
      name="integration-navigator"
      spec={
        license={
          accept= true
          license= var.license
        }
        mqDashboard=true
        version=var.instance_version
        storage={
          class=var.storageclass
        }
        replicas=var.replica_count
      }
    }

  }
  values_file = "values.yaml"
  layer = "services"
  application_branch = "main"
  type="instances"
  layer_config = var.gitops_config[local.layer]
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

#This one is for creating subscription yaml
resource null_resource create_subscription_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.subscription_name}' '${local.subscription_chart_dir}' '${local.subscription_yaml_dir}' '${local.values_file}'"
    
    environment = {
      VALUES_CONTENT = yamlencode(local.subscription_values_content)
    }
  }
}

resource gitops_module setup_subscription_gitops {
  depends_on = [null_resource.create_subscription_yaml]

  name = local.subscription_name
  namespace = local.subscription_namespace
  content_dir = local.subscription_yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = "operators"
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

module pull_secret {
  source = "github.com/cloud-native-toolkit/terraform-gitops-pull-secret"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  server_name = var.server_name
  kubeseal_cert = var.kubeseal_cert
  namespace = var.namespace
  docker_username = "cp"
  docker_password = var.entitlement_key
  docker_server   = "cp.icr.io"
  secret_name     = "ibm-entitlement-key"
}

resource null_resource create_instance_yaml {
  depends_on = [resource.setup_subscription_gitops]
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.instance_name}' '${local.instance_chart_dir}' '${local.instance_yaml_dir}' '${local.values_file}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.instance_values_content)
    }
  }
}

resource gitops_module setup_instance_gitops {
  depends_on = [null_resource.create_instance_yaml]

  name = local.instance_name
  namespace = var.namespace
  content_dir = local.instance_yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
