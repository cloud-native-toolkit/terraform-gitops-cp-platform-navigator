locals {
  base_name     = "ibm-platform-navigator"
  subscription_name = local.base_name
  instance_name = "${local.base_name}-instance"
  bin_dir       = module.setup_clis.bin_dir
  subscription_chart_dir = "${path.module}/charts/ibm-platoform-navigator"
  subscription_yaml_dir = "${path.cwd}/.tmp/${local.base_name}/chart/${local.subscription_name}"
  instance_chart_dir = "${path.module}/charts/ibm-platoform-navigator-instance"
  instance_yaml_dir     = "${path.cwd}/.tmp/${local.base_name}/chart/${local.instance_name}"
  subscription_values_content = {
    "ibm-platform-navigator" = {
      subscriptions = {
        platformnavigator = {
          name = local.subscription_name
          subscription = {
            channel = var.channel
            installPlanApproval = "Automatic"
            name = "ibm-integration-platform-navigator"
            source = var.catalog
            sourceNamespace = var.catalog_namespace
          }
        }
      }
    }
  }
  instance_values_content = {
    "ibm-platform-navigator-instance" = {
      ibmplatformnavigator = {
        name = "integration-navigator"
        spec = {
          license = {
            accept = true
            license = var.license

          }
          mqDashboard = true
          version = var.instance_version
          replicas = var.replica_count
        }
      }
    }
  }
  values_file = "values-${var.server_name}.yaml"
  layer = "services"
  application_branch = "main"
  layer_config = var.gitops_config[local.layer]
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

resource null_resource create_subscription_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.subscription_name}' '${local.subscription_chart_dir}' '${local.subscription_yaml_dir}' '${local.values_file}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.subscription_values_content)
    }
  }
}

resource null_resource setup_subscription_gitops {
  depends_on = [null_resource.create_subscription_yaml]

  provisioner "local-exec" {
    command = "${local.bin_dir}/igc gitops-module '${local.subscription_name}' -n '${var.subscription_namespace}' --contentDir '${local.subscription_yaml_dir}' --serverName '${var.server_name}' -l '${local.layer}' --type=operators --valueFiles='values.yaml,${local.values_file}'"

    environment = {
      GIT_CREDENTIALS = yamlencode(var.git_credentials)
      GITOPS_CONFIG   = yamlencode(var.gitops_config)
    }
  }
}

resource null_resource create_instance_yaml {
  depends_on = [null_resource.setup_subscription_gitops]
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.instance_name}' '${local.instance_chart_dir}' '${local.instance_yaml_dir}' '${local.values_file}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.instance_values_content)
    }
  }
}

resource null_resource setup_instance_gitops {
  depends_on = [null_resource.create_instance_yaml]

  provisioner "local-exec" {
    command = "${local.bin_dir}/igc gitops-module '${local.instance_name}' -n '${var.namespace}' --contentDir '${local.instance_yaml_dir}' --serverName '${var.server_name}' -l '${local.layer}' --type=instances --valueFiles='values.yaml,${local.values_file}'"

    environment = {
      GIT_CREDENTIALS = yamlencode(var.git_credentials)
      GITOPS_CONFIG   = yamlencode(var.gitops_config)
    }
  }
}
