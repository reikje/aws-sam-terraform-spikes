variable "namespace" {
  default = "namespace"
}

variable "project" {
  default = "project"
}

variable "environment" {
  default = "dev"
}

locals {
  resource_prefix = "${var.namespace}-${var.project}-${var.environment}"
}

resource "terraform_data" "sam_build" {
  triggers_replace = timestamp()
  provisioner "local-exec" {
    command = "sam build"
    working_dir = ".."
  }
}

resource "terraform_data" "sam_deploy" {
  triggers_replace = timestamp()
  provisioner "local-exec" {
    command = "sam deploy --stack-name ${local.resource_prefix} --no-fail-on-empty-changeset --region us-east-1"
    working_dir = ".."
  }
  depends_on = [ terraform_data.sam_build ]
}

resource "terraform_data" "sam_destroy" {
  for_each = toset()
  provisioner "local-exec" {
    command = "aws cloudformation delete-stack --stack-name ${var.namespace}-${var.project}-${var.environment} --region us-east-1"
    when    = destroy
  }
}
