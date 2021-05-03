# Hello World 
**Title:**

Terraform code to provision the AWS infrastructure to deploy hello world application on kubernetes pods

**Summary of steps:**

This terraform code repo helps to commission a simple hello world jsp application on the AWS cloud within 15 minutes. One has to create terraform.tfvars with aws access key and secret access key details. Following steps have to be executed in order as below:

1) Download the scripts and create terraform.tfvars with aws_access_key, aws_secret_key and default region details. Also, make sure the ip address is updated in the ingress section of the security group.
2) initialize terraform with necessary providers and plugins by:
   terraform init
3) Once terraform is initialized, the cloud resources can be created as below:
   terraform plan (to verify the cloud resourced that will get created)
   terraform apply to apply the changes to aws
4) In this configuration a root instance is created to provison kubernetes clusters using terraform. Before the instance is created vpc, security group and route table resources are created using terraform. The key pair name has been hard coded in ec2.tf and the pem file has been attached with this repository.
5) remote-exec provisioner executes the commands to download the binaries for kops and kubectl
6) Once these utilities are installed, kubernetes cluster can be created using kops create cluster command as below:
   kops create cluster --cloud=aws --zones=eu-west-2a,eu-west-2b,eu-west-2c --master-size t2.medium --master-zones eu-west-2a,eu-west-2b,eu-west-2c --node-size t2.medium --node-count 5 --name=hwdemo.k8s.helloworld.demo --dns-zone=helloworld.demo --dns private",

7) After the above step, one can change the instance and master/worker configuration details using kops edit command. Otherwise kops update command can be executed to create the cluster.
8) Since kops takes 10-15 minutes to create the cluster, a sleep has been introduced to get these changes done as IP address of the api.<cluster_name> needs to be known by the workers for clean configuration.
9) Once kops creates the cluster a tomcat web server with a sample hello world web application which was built using docker has been deployed on kubernetes with replicas. 
10) The application can be accessed via browser using the public ip of the master nodes as follows: http://public-ip-of-master:NodePort/sample. Here 'sample' is the application that has been built using docker with tomcat web server.

**High Availiability and Fault Tolerance:**

Kubernetes clusters are highly available as they span across 3 AZs. It is a multi-master and multi-worker configuration. Also KOPS takes care of the instance availabilty via auto scaling group. The hello world jsp application has been deployed on Tomcat server with 5 replicas. A kubernetes service of type load balancer has been created to access the application outside the cluster.

**Conclusion:**

A highly available web application can be created on AWS cloud within 15 minutes using kops and terraform as discussed above. 
