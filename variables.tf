
variable "instance_type" {
  description = "type of instances to provision"
  default="m4.large"
}

variable "aws_profile" {
  description = "aws profile : defaults to nasuni"
  default = "nasuni"
}
variable "region" {
  description = "VPC region: defaults to us-east-2 (Ohio)"
  default = "us-east-2"
}
variable "volume_size" {
  description = "volume_size default is set as 32GiB"
  default=500
}

variable "nac_scheduler_name" {
  description = "nac_scheduler_name by default is NACScheduler"
  default="NACScheduler"
}

variable "pem_key_file" {
  description = "Pem Key file path to be used to SSH the NACScheduler instance"
  default = ""
}
variable "aws_key" {
  description = "Key Pair Name used to provision the NAC Scheduler instance"
  default = ""
}
variable "github_organization" {
  description = "github organization used by Users, default is nasuni-labs"
  default = "nasuni-labs"
}
variable "git_repo_ui" {
  description = "git_repo_ui specific to certain repos"
  default = "nasuni-opensearch-userinterface"
}
variable "user_vpc_id" {
  default=""
}

variable "service_name" {
  default=""
}

variable "user_subnet_id" {
  default=""
}
variable "subnet_availability_zone" {
  default=""
}
variable "use_private_ip" {
  default=""
}
variable "git_branch" {
  default=""
}

variable "nac_es_securitygroup_id" {
  type    = string
  default = ""
}
