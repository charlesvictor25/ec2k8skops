#providers
provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region = "${var.region}"
}
#data "template_file" "user_data" {
#  template = file("kops.sh")
#}
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "hwpico"
  }
}

resource "aws_route53_zone" "private" {
  name = "helloworld.pico"

  vpc {
    vpc_id = "${aws_vpc.vpc.id}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Environment = "${var.environment_tag}"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr_subnet}"
  map_public_ip_on_launch = "true"
  availability_zone = "${var.availability_zone}"
  tags = {
    Environment = "${var.environment_tag}"
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Environment = "${var.environment_tag}"
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = "${aws_subnet.subnet_public.id}"
  route_table_id = "${aws_route_table.rtb_public.id}"
}

resource "aws_security_group" "sec_group" {
  name = "sec_group"
  vpc_id = "${aws_vpc.vpc.id}"

  # SSH access from the VPC
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["<public_ip>"]
  }

  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment_tag}"
  }
}


resource "aws_instance" "ec2Instance" {
  ami           = "${var.instance_ami}"
  instance_type = "${var.instance_type}"
  subnet_id = "${aws_subnet.subnet_public.id}"
  vpc_security_group_ids = ["${aws_security_group.sec_group.id}"]
  iam_instance_profile = "k8s_profile"
  #user_data     = data.template_file.user_data.rendered
  key_name = "DevOps"

  tags = {
		Name = "Hello World - PICO"
	}

  provisioner "remote-exec" {
    inline = [
      "aws s3 mb s3://hwpico.k8s.helloworld.pico",
      "export KOPS_STATE_STORE=s3://hwpico.k8s.helloworld.pico",
      "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa <<< y",
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",
      "curl -LO  https://github.com/kubernetes/kops/releases/download/1.15.0/kops-linux-amd64",
      "chmod +x kops-linux-amd64",
      "sudo mv kops-linux-amd64 /usr/local/bin/kops",
      "export PATH=/usr/local/bin:$PATH",
      "kops create cluster --cloud=aws --zones=eu-west-2a,eu-west-2b,eu-west-2c --master-zones eu-west-2a,eu-west-2b,eu-west-2c --node-count 5 --name=hwpico.k8s.helloworld.pico --dns-zone=helloworld.pico --dns private",
      "kops update cluster --name hwpico.k8s.helloworld.pico --yes",
      "sleep 600",
      "kops validate cluster",
      "kubectl create deploy tomcat --image=charlesvictor/tomcat:latest --replicas=4 --port=8080",
      "kubectl expose deployment tomcat --port=8080 --type=LoadBalancer",
      "echo This is the Public IP of the EC2 instance: ${aws_instance.ec2Instance.public_ip}",
      #"echo This is the URL of the hello world application: ",
      #"echo "$(echo "http://")""$(echo "$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')")""$(echo ":")""$(echo "$(kubectl get svc -o go-template='{{range .items}}{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}{{end}}')")""$(echo "/sample")"" ,

    ]
  }

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = ""
    private_key = file("./DevOps.pem")
    host = self.public_ip
    #host = "${aws_instance.testInstance.ipv4_address}"
  }
}
