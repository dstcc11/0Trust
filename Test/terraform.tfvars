tfc_organization_name = "KuTest"
tfc_project_name      = "Test"

workspaces = {
  "KUBRA_test" = {
    working_directory   = "/Test/0Root"
    vcs_repo_identifier = "dstcc11/KUBRA_test"
    trigger_patterns    = ["/Test/**/*"]
  }
}