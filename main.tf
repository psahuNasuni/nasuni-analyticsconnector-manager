
##main
locals{
git_repo_ui = var.use_private_ip != "Y" ? "nasuni-opensearch-userinterface-public" : "nasuni-opensearch-userinterface" 
}
# instances
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

data "aws_region" current {}
data "aws_vpc" "default" {
  default = true
}

resource "random_id" "unique_sg_id" {
  byte_length = 3
}


data "aws_vpc" "VPCtoBeUsed" {
  id = var.user_vpc_id != "" ? var.user_vpc_id : data.aws_vpc.default.id 
}

data "aws_subnet_ids" "FetchingSubnetIDs" {
  vpc_id = data.aws_vpc.VPCtoBeUsed.id
}
data "aws_subnet" "example" {
 for_each = data.aws_subnet_ids.FetchingSubnetIDs.ids
 id  = each.value
}

resource "aws_instance" "NACScheduler" {
  ami = data.aws_ami.ubuntu.id
  availability_zone = var.subnet_availability_zone
  instance_type = "${var.instance_type}"
  key_name = "${var.aws_key}"
  associate_public_ip_address = var.use_private_ip != "Y" ? true : false
  # associate_public_ip_address = true
  source_dest_check = false
  subnet_id = var.user_subnet_id != "" ? var.user_subnet_id : element(tolist(data.aws_subnet_ids.FetchingSubnetIDs.ids),0) 
  root_block_device {
    volume_size = var.volume_size
  }
  vpc_security_group_ids = [ var.nac_es_securitygroup_id ]
  tags = {
    Name            = var.nac_scheduler_name
    Application     = "Nasuni Analytics Connector with Elasticsearch"
    Developer       = "Nasuni"
    PublicationType = "Nasuni Labs"
    Version         = "V 0.1"

  }

depends_on = [
  data.local_file.aws_conf_access_key,
  data.local_file.aws_conf_secret_key
]
}

resource "null_resource" "update_secGrp" {
  provisioner "local-exec" {
     command = "sh update_secGrp.sh ${aws_instance.NACScheduler.public_ip} ${var.nac_scheduler_name} ${data.aws_region.current.name} ${var.aws_profile} "
  }
  depends_on = [aws_instance.NACScheduler]
}

resource "null_resource" "NACScheduler_IP" {
  provisioner "local-exec" {
    command = var.use_private_ip != "Y" ? "echo ${aws_instance.NACScheduler.public_ip} > NACScheduler_IP.txt" : "echo ${aws_instance.NACScheduler.private_ip} > NACScheduler_IP.txt"
  }
  depends_on = [aws_instance.NACScheduler]
}

resource "null_resource" "aws_conf" {
  provisioner "local-exec" {
     command = "aws configure get aws_access_key_id --profile ${var.aws_profile} | xargs > awacck.txt && aws configure get aws_secret_access_key --profile ${var.aws_profile} | xargs > awsecck.txt"
  }
}

data "local_file" "aws_conf_access_key" {
  filename   = "${path.cwd}/awacck.txt"
  depends_on = [null_resource.aws_conf]
}


data "local_file" "aws_conf_secret_key" {
  filename   = "${path.cwd}/awsecck.txt"
  depends_on = [null_resource.aws_conf]
}

 resource "null_resource" "Inatall_Packages" {
 provisioner "remote-exec" {
    inline = [
      "echo '@@@@@@@@@@@@@@@@@@@@@ STARTED - Inastall Packages @@@@@@@@@@@@@@@@@@@@@@@'",
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt install dos2unix -y",
      "sudo apt install curl bash ca-certificates git openssl wget vim -y",
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt update",
      "sudo apt install terraform",
      "terraform -v",
      "which terraform",
      "echo @@@@@@@@@@@ terraform Installed @@@@@@@@@",
      "sudo apt install jq -y",
      "sudo apt install zip -y",
      "sudo apt install unzip -y",
      "sudo apt install python3.9 -y",
      "sudo apt install python3-pip -y",
      "alias python3='/usr/bin/python3.9'",
      "alias pip3='python3.9 -m pip'",
      "sudo pip3 install boto3",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
      "sudo unzip awscliv2.zip",
      "sudo ./aws/install",
      "aws --version",
      "which aws",
      "aws configure --profile ${var.aws_profile} set aws_access_key_id ${data.local_file.aws_conf_access_key.content}",
      "aws configure --profile ${var.aws_profile} set aws_secret_access_key ${data.local_file.aws_conf_secret_key.content}",
      "aws configure set region ${data.aws_region.current.name} --profile ${var.aws_profile}",
      "sudo apt update",
      "echo '@@@@@@@@@@@@@@@@@@@@@ FINISHED - Inastall Packages @@@@@@@@@@@@@@@@@@@@@@@'"
      ]
  }

  connection {
    type        = "ssh"
    host = var.use_private_ip != "Y" ? aws_instance.NACScheduler.public_ip : aws_instance.NACScheduler.private_ip
    user        = "ubuntu"
    private_key = file("./${var.pem_key_file}")
  }
  depends_on = [null_resource.update_secGrp]
 }

resource "null_resource" "Inatall_APACHE" {
  #count = var.service_name == "KENDRA" ? 0 : 1
 provisioner "remote-exec" {
    inline = [
      "echo '@@@@@@@@@@@@@@@@@@@@@ STARTED - Inastall WEB Server            @@@@@@@@@@@@@@@@@@@@@@@'",
      "sudo apt update",
      "sudo apt install apache2 -y",
      "sudo ufw app list",
      "sudo ufw allow 'Apache'",
      "sudo service apache2 restart",
      "sudo apt install dos2unix -y",
      "echo '@@@@@@@@@@@@@@@@@@@@@ FINISHED - Inastall WEB Server             @@@@@@@@@@@@@@@@@@@@@@@'",
      "echo '@@@@@@@@@@@@@@@@@@@@@ STARTED  - Deployment of SearchUI Web Site @@@@@@@@@@@@@@@@@@@@@@@'",
      ]
  }
  connection {
    type        = "ssh"
    # host        = aws_instance.NACScheduler.public_ip
    host = var.use_private_ip != "Y" ? aws_instance.NACScheduler.public_ip : aws_instance.NACScheduler.private_ip
    user        = "ubuntu"
    private_key = file("./${var.pem_key_file}")
  }
  depends_on = [null_resource.Inatall_Packages]
}

resource "null_resource" "cleanup_temp_files" {
   provisioner "local-exec" {
    command = "echo . > awacck.txt && echo . > awsecck.txt"
  }
   provisioner "local-exec" {
    when    = destroy
    command = "rm -rf *cck.txt"
  }
  #depends_on = [null_resource.Inatall_APACHE]
}

locals {
  NACScheduler-IP = var.use_private_ip != "Y" ? aws_instance.NACScheduler.public_ip : aws_instance.NACScheduler.private_ip
}


  
