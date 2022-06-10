#!/bin/bash
#################################################################################
### This script is to enable local computer to access (SSH) to a remote EC2. 
### i.e It can Update the Security Group of a target EC2 instance 
### with local computer's IP Address 
### This script can be executed with 4 input arguments( Example as below command):
###         ./update_SecGrp.sh 52.91.85.207 nac-test-pk us-east-1 nasuni 
### 			1st Argument : Target IP Address
###				2nd Argument : Target Instance Name
###				3rd Argument : AWS Region
###				4th Argument : AWS Profile
###########################################################################

NAC_SCHEDULER_IP_ADDR=$1
NAC_SCHEDULER_NAME=$2
AWS_REGION=$3
AWS_PROFILE=$4
add_ip_to_sec_grp() {
	echo "INFO ::: Getting Public IP of the local machine."
	LOCAL_IP=`curl checkip.amazonaws.com`
	
	echo "INFO ::: Public IP of the local machine is ${LOCAL_IP}"
	NEW_CIDR="${LOCAL_IP}"/32
	echo "INFO ::: NEW_CIDR :- ${NEW_CIDR}"
	if [ "$NAC_SCHEDULER_NAME" != "" ]; then
		SECURITY_GROUP_ID=$(aws ec2 describe-instances --query "Reservations[].Instances[].{Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,PublicIP:PublicIpAddress,SecurityGroups:SecurityGroups[*]}" --filters "Name=tag:Name,Values='$NAC_SCHEDULER_NAME'" "Name=instance-state-name,Values=running" --region $AWS_REGION --profile "${AWS_PROFILE}" | grep -e "GroupId" | cut -d":" -f 2 | tr -d '"')
		echo $SECURITY_GROUP_ID
		echo "INFO ::: Security group of $NAC_SCHEDULER_NAME is $SECURITY_GROUP_ID"
	else
		echo "INFO ::: NAC Scheduler Instance $NAC_SCHEDULER_NAME is present .So fetching its security group . . . . . "
		SECURITY_GROUP_ID=`aws ec2 describe-instances --query "Reservations[].Instances[].{Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,PublicIP:PublicIpAddress,SecurityGroups:SecurityGroups[*]}" --filters "Name=tag:Name,Values='NACScheduler'" "Name=instance-state-name,Values=running" --region $AWS_REGION  --profile "${AWS_PROFILE}" | grep -e "GroupId" | cut -d":" -f 2 | tr -d '"'`
		echo "INFO ::: Security group of NAC Scheduler Instance $NAC_SCHEDULER_NAME is $SECURITY_GROUP_ID"
	# else
	# 	echo "INFO ::: NAC Scheduler Instance $NAC_SCHEDULER_NAME is Not present. "
	fi
	#If OS name is windows
	status=$(aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --profile "${AWS_PROFILE}" --protocol tcp --port 22 --cidr ${NEW_CIDR} 2>/dev/null)
	status80=$(aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --profile "${AWS_PROFILE}" --protocol tcp --port 80 --cidr ${NEW_CIDR} 2>/dev/null)
	status443=$(aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --profile "${AWS_PROFILE}" --protocol tcp --port 443 --cidr ${NEW_CIDR} 2>/dev/null)
	status8080=$(aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --profile "${AWS_PROFILE}" --protocol tcp --port 8080 --cidr ${NEW_CIDR} 2>/dev/null)
	# aws ec2 authorize-security-group-ingress --group-name sg-a3204ac8 --protocol tcp --port 22 --cidr 103.168.202.24/24
	if [ $? -eq 0 ]; then
		echo "INFO ::: Local Computer IP $NEW_CIDR updated to inbound rule of Security Group $SECURITY_GROUP_ID"
	else
		echo "INFO ::: IP $NEW_CIDR already available in inbound rule of Security Group $SECURITY_GROUP_ID"
		# echo "FAIL"
	fi

}

add_ip_to_sec_grp $NAC_SCHEDULER_IP_ADDR $NAC_SCHEDULER_NAME $AWS_REGION $AWS_PROFILE
