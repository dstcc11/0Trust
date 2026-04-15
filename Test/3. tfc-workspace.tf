# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "tfe" {
  hostname = var.tfc_hostname
}

# Data source used to grab the project under which a workspace will be created.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/project
data "tfe_project" "tfc_project" {
  name         = var.tfc_project_name
  organization = var.tfc_organization_name
}

# Runs in this workspace will be automatically authenticated
# to AWS with the permissions set in the AWS policy.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace

data "tfe_oauth_client" "client" {
  organization     = var.tfc_organization_name
  service_provider = "github"
}

# output "tfe_oauth_client" {
#   value = {
#     name                          = data.tfe_oauth_client.client.name
#     id                            = data.tfe_oauth_client.client.id
#     api_url                       = data.tfe_oauth_client.client.api_url
#     callback_url                  = data.tfe_oauth_client.client.callback_url
#     http_url                      = data.tfe_oauth_client.client.http_url
#     oauth_token_id                = data.tfe_oauth_client.client.oauth_token_id
#     service_provider              = data.tfe_oauth_client.client.service_provider
#     service_provider_display_name = data.tfe_oauth_client.client.service_provider_display_name
#   }
# }

resource "tfe_workspace" "my_workspace" {
  for_each                      = var.workspaces
  name                          = each.key
  organization                  = var.tfc_organization_name
  project_id                    = data.tfe_project.tfc_project.id
  working_directory             = each.value.working_directory
  auto_apply                    = true
  auto_apply_run_trigger        = true
  terraform_version             = "latest"
  structured_run_output_enabled = false
  force_delete                  = true
  trigger_patterns              = each.value.trigger_patterns
  vcs_repo {
    identifier     = each.value.vcs_repo_identifier
    oauth_token_id = data.tfe_oauth_client.client.oauth_token_id
  }
}

# The following variables must be set to allow runs
# to authenticate to AWS.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable
resource "tfe_variable" "enable_aws_provider_auth" {
  for_each     = tfe_workspace.my_workspace
  workspace_id = each.value.id
  key          = "TFC_AWS_PROVIDER_AUTH"
  value        = "true"
  category     = "env"
  description  = "Workload Identity integration for AWS"
}

resource "tfe_variable" "tfc_aws_role_arn" {
  for_each     = tfe_workspace.my_workspace
  workspace_id = each.value.id
  key          = "TFC_AWS_RUN_ROLE_ARN"
  value        = aws_iam_role.tfc_role[each.key].arn
  category     = "env"
  sensitive    = "true"
  description  = "The AWS role arn for authenticatication"
}

# The following variables are optional; uncomment the ones you need!

# resource "tfe_variable" "tfc_aws_audience" {
#   workspace_id = tfe_workspace.my_workspace.id

#   key      = "TFC_AWS_WORKLOAD_IDENTITY_AUDIENCE"
#   value    = var.tfc_aws_audience
#   category = "env"

#   description = "The value to use as the audience claim in run identity tokens"
# }

# The following is an example of the naming format used to define variables for
# additional configurations. Additional required configuration values must also
# be supplied in this same format, as well as any desired optional configuration
# values.
#
# Additional configurations can be used to uniquely authenticate multiple aliases
# of the same provider in a workspace, with different roles/permissions in different
# accounts or regions.
#
# See https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/specifying-multiple-configurations
# for more details on specifying multiple configurations.
#
# See https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration#specifying-multiple-configurations
# for specific requirements and details for the AWS provider.

# resource "tfe_variable" "enable_aws_provider_auth_other_config" {
#   workspace_id = tfe_workspace.my_workspace.id

#   key      = "TFC_AWS_PROVIDER_AUTH_other_config"
#   value    = "true"
#   category = "env"

#   description = "Enable the Workload Identity integration for AWS for an additional configuration named other_config."
# }
