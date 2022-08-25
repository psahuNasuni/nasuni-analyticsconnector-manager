#!/bin/bash
export TF_LOG=debug
export TF_LOG_PATH=./terraform_UnitTestNAC.log

NAC_TFVARS="$1"

exit_status=0
check_if_terraform_exists(){
   terraform -version || exit_status=$?
if [ $exit_status -eq 0 ]; then
    echo "INFO ::: Terraform installed"
elif [ $exit_status -eq 1 ]; then
    echo "ERROR ::: Terraform not installed"
    exit 1
fi
}

check_if_terraform_exists
echo "INFO ::: NAC_EC2_Instance provisioning ::: BEGIN ::: Executing ::: Terraform Init ."
cp ./NAC.tfvars ../
sudo chmod 755 sso-us-east-2.pem
cp ./sso-us-east-2.pem ../
cd ..
terraform init
echo "INFO ::: NAC_EC2_Instance provisioning ::: FINISHED ::: Executing ::: Terraform Init  ."

echo "INFO ::: NAC_EC2_Instance provisioning ::: BEGIN ::: Executing ::: Terraform apply  ."
COMMAND="terraform apply -var-file=$NAC_TFVARS -auto-approve"
$COMMAND || exit_status=$?

if [ $exit_status -eq 0 ]; then
    echo "INFO ::: NAC_EC2_Instance provisioning ::: FINISHED ::: Executing ::: Terraform apply  ."
    

elif [ $exit_status -eq 1 ]; then
    echo "INFO ::: NAC_EC2_Instance provisioning ::: FAILED ::: Executing ::: Terraform apply  ."
    exit 1
fi

echo "INFO ::: NAC_EC2_Instance provisioning ::: BEGIN ::: DESTROY INFRA ::: Terraform Destroy."
terraform destroy -var-file=$NAC_TFVARS -auto-approve
echo "INFO ::: NAC_EC2_Instance provisioning ::: COMPLETED ::: DESTROY INFRA ::: Terraform Destroy."

