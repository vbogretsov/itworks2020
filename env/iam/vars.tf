variable "tfstate" {
  type        = string
  description = "Terraform state bucket name."
}

variable "prefix" {
  type        = string
  description = "Project prefix."
}

variable "domain" {
  type        = string
  description = "Domain name registered in Route 53."
}
