provider "aws" {}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}


terraform {
  required_version = ">= 0.12"

  backend "s3" {
    workspace_key_prefix = ""
    key                  = "itworks2020-res.tfstate"
  }

  required_providers {
    aws = "= 2.36.0"
  }
}

locals {
  bucket    = "${var.prefix}-${replace(var.domain, ".", "-")}"
  origin_id = "${var.prefix}-s3origin"
  domain    = "${var.prefix}.${var.domain}"
}

data "aws_route53_zone" "this" {
  name         = "${var.domain}."
  private_zone = false
}

data "aws_iam_policy_document" "bucket" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]

    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.this.iam_arn,
      ]
    }
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.this.arn,
    ]

    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.this.iam_arn
      ]
    }
  }
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket
  acl    = "private"
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket.json
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "Static files bucket for ItWorks 2020"
}

resource "aws_cloudfront_distribution" "this" {
  provider = aws.us_east_1

  enabled             = true
  default_root_object = "index.html"

  aliases = [
    local.domain,
  ]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
    compress    = false

    viewer_protocol_policy = "redirect-to-https"
  }

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.this.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "alias" {
  zone_id = data.aws_route53_zone.this.id
  name    = var.prefix
  type    = "CNAME"
  ttl     = 60

  records = [
    aws_cloudfront_distribution.this.domain_name
  ]
}

resource "aws_acm_certificate" "this" {
  provider          = aws.us_east_1
  domain_name       = local.domain
  validation_method = "DNS"
}

resource "aws_route53_record" "cert" {
  name    = aws_acm_certificate.this.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.this.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.this.id
  records = [aws_acm_certificate.this.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [aws_route53_record.cert.fqdn]
}
