resource "aws_ebs_volume" "myvol" {
        availability_zone = aws_instance.web.availability_zone
		size = 10
		type = "gp3"
		tags = {
		        Name = "my-disk"
		}
}

resource "aws_volume_attachment" "myattachvol" {
        device_name = "/dev/xvdf"
		volume_id = aws_ebs_volume.myvol.id
		instance_id = aws_instance.web.id
}


resource "aws_security_group" "my_s_g" {
	     name = "test-group-ssh-apche"
		 description = "ssh and apache port open"
		 
		 ingress {
		          from_port = 22
				  to_port = 22
				  protocol = "tcp"
				  cidr_blocks = ["0.0.0.0/0"]
         }
		  ingress {
		          from_port = 80
				  to_port = 80
				  protocol = "tcp"
				  cidr_blocks = ["0.0.0.0/0"]
         }		  
		 egress {
		         from_port = 0
				 to_port = 0
				 protocol = "-1"
				 cidr_blocks = ["0.0.0.0/0"]
		 }
}

data "aws_ami" "myaws-linux" {
         owners = ["amazon"]
		 most_recent = true
		 filter {
		         name = "name"
				 values = ["amzn2-ami-hvm-*-x86_64-gp2"]
		 }
}

resource "aws_instance" "web" {
       ami = data.aws_ami.myaws-linux.id 
      instance_type = "t3.micro"
	  key_name = aws_key_pair.my_key.key_name
	  
	  connection {
	            type = "ssh"
				user = "ec2-user"
				private_key = "C:/Users/admin/.ssh/id_ed25519"
				host = self.public_ip
	   }
	   
	   
	   provisioner "remote-exec" {
	           inline = [ 
			             "sudo yum install git docker-io -y",
			             " sudo install wget -y",
						 " sudo touch /tmp/demo.txt"
						 ]
		}

      provisioner "file" {
              source = "ip_info.txt"
			  destination = "/mnt/ip_info.txt"
      }	  
	  provisioner "local-exec" {
	            command = "echo Public IP is ${self.public_ip} > ip_info.txt"
	  }
	  provisioner "local-exec" {
	            command = "echo Private IP is ${self.private_ip} >> ip_info.txt"
   	  }
	  vpc_security_group_ids = [aws_security_group.my_s_g.id]
	  tags = {
	          Name="web"
	   }
}

resource "aws_key_pair" "my_key" {
    key_name = "terra-key"
    public_key = file("C:/Users/admin/.ssh/id_ed25519.pub")	
}


output "public-ip" {
        value = "Ec2 IP is: ${aws_instance.web.public_ip}"
}

output "private-ip" {
        value = "Ec2 IP is: ${aws_instance.web.private_ip}"
}
