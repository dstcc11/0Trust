module "circleci-aws-oidc" {
  source              = "./modules/"
  circleci_org_id     = "949dff8a-3534-4a1e-b5ee-3bb5238abc2c"
  circleci_project_id = "*"
}