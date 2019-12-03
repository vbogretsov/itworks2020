provider "aws" {}

terraform {
  required_version = ">= 0.12"

  backend "s3" {
    workspace_key_prefix = ""
    key                  = "itworks2020-iam.tfstate"
  }

  required_providers {
    aws = "= 2.36.0"
  }
}

locals {
  bucket     = "${var.prefix}-${replace(var.domain, ".", "-")}"
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
  statename  = "itworks2020-res.tfstate"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "this" {
  name         = "${var.domain}."
  private_zone = false
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.tfstate}/*/${local.statename}",
      "arn:aws:s3:::${var.tfstate}/${local.statename}",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.tfstate}",
    ]
  }

  statement {
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:ListBucket",
      "s3:GetBucket*",
      "s3:GetAccountPublicAccessBlock",
      "s3:Get*Configuration",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket}"
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket}/*"
    ]
  }

  statement {
    actions = [
      "cloudfront:*CloudFrontOriginAccessIdentity*",
    ]

    resources = [
      # "arn:aws:cloudfront::${local.account_id}:origin-access-identity/*"
      "*"
    ]
  }

  statement {
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:UpdateDistribution",
      "cloudfront:ListTagsForResource",
      "cloudfront:*agResource",
    ]

    resources = [
      "arn:aws:cloudfront::${local.account_id}:distribution/*"
    ]
  }

  statement {
    actions = [
      "cloudfront:ListDistributions",
      "cloudfront:ListCloudFrontOriginAccessIdentities",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "route53:GetChange",
    ]

    resources = [
      "arn:aws:route53:::change/*"
    ]
  }

  statement {
    actions = [
      "route53:GetHostedZone",
      "route53:*RecordSets",
    ]

    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.this.id}"
    ]
  }

  statement {
    actions = [
      "acm:DeleteCertificate",
      "acm:DescribeCertificate",
      "acm:GetCertificate",
      "acm:UpdateCertificateOptions",
      "acm:ListTagsForCertificate",
    ]

    resources = [
      "arn:aws:acm:${local.region}:${local.account_id}:certificate/*",
      "arn:aws:acm:us-east-1:${local.account_id}:certificate/*",
    ]
  }

  statement {
    actions = [
      "acm:RequestCertificate",
      "acm:ListCertificates",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ec2:DescribeAccountAttributes",
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.account_id}:root"
      ]
    }
  }
}

data "aws_iam_policy_document" "group" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.this.arn]
  }
}

resource "aws_iam_role" "this" {
  name               = var.prefix
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "this" {
  name   = var.prefix
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_group" "this" {
  name = var.prefix
}

resource "aws_iam_group_policy" "this" {
  name   = var.prefix
  group  = aws_iam_group.this.id
  policy = data.aws_iam_policy_document.group.json
}
