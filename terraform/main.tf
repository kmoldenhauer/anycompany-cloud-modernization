# terraform/main.tf

# Generates a random 6-character lowercase suffix for globally unique resources (like S3 buckets)
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}