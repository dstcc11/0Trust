locals {
  circleci_oidc_url = "oidc.circleci.com/org/${var.circleci_org_id}"
  assume_role_value = "org/${var.circleci_org_id}/project/${var.circleci_project_id}/user/*"
}

# Identity Provider
resource "aws_iam_openid_connect_provider" "circleci_provider" {
  url = "https://${local.circleci_oidc_url}"

  client_id_list = [
    var.circleci_org_id,
  ]

  thumbprint_list = [for thumbprint in var.thumbprints : thumbprint]
}


# Trusted role for Web Identity
resource "aws_iam_role" "circleci_role" {
  name               = "CircleCI_Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.circleci_provider.arn}"
      },
      "Condition": {
        "StringLike": {
          "${local.circleci_oidc_url}:sub": "${local.assume_role_value}"
        }
      }
    }
  ]
}
EOF
}

# Allow Full access
resource "aws_iam_policy" "circleci_policy" {
  name        = "CircleCI-Policy"
  description = "CircleCi run policy"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "tfc_policy_attachment" {
  role       = aws_iam_role.circleci_role.name
  policy_arn = aws_iam_policy.circleci_policy.arn
}

