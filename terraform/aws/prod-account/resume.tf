# S3 static website bucket
resource "aws_s3_bucket" "default" {
  bucket = var.resume_bucket
  tags = {
    Name        = "resume-bucket"
    Environment = "production"
  }
}
data "cloudflare_zone" "default" {
  name = var.domain_name
}

# CloudFlare CloudConnector rule for routing to S3
resource "cloudflare_cloud_connector_rules" "resume_s3_routing" {
  zone_id = data.cloudflare_zone.default.id

  rules {
    description = "Route resume website to AWS S3 bucket"
    enabled     = true
    expression  = "http.request.full_uri wildcard \"https://${var.resume_subdomain}.${var.domain_name}/*\""
    provider    = "aws_s3"

    parameters {
      host = aws_s3_bucket_website_configuration.default.website_endpoint
    }
  }
}

# S3 bucket public access configuration
resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "default" {
  bucket = aws_s3_bucket.default.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 bucket policy for public read access
resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.default.id

  depends_on = [aws_s3_bucket_public_access_block.default]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.default.arn}/*"
      }
    ]
  })
}

# Outputs
output "s3_website_endpoint" {
  description = "S3 website endpoint for CloudFlare CNAME configuration"
  value       = aws_s3_bucket_website_configuration.default.website_endpoint
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.default.bucket_domain_name
}

output "resume_website_url" {
  description = "Resume website URL"
  value       = "https://${var.resume_subdomain}.${var.domain_name}"
}
