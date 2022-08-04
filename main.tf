#######----create bucket------#######
variable "s3_bucket_name" {
   type = list(string)
   default = ["bucket123-new-1", "bucket123-new-2", "bucket123-new-3", "bucket123-new-4", "bucket123-new-5", "bucket123-new-6", "bucket123-new-7", "bucket123-new-8", "bucket123-new-9", "bucket123-new-10"]
}
resource "aws_s3_bucket" "new-bucket" {
   count = "${length(var.s3_bucket_name)}"
   bucket = "${var.s3_bucket_name[count.index]}"
   acl = "private"
   versioning {
      enabled = true
   }
   force_destroy = "true"
}



#######----create user------#######
resource "aws_iam_user" "user" {
  name = "rohit"
}
# resource "aws_iam_policy" "policy" {
#   name        = "policy"
#   description = "A test policy"
#   arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess , arn:aws:iam::aws:policy/AmazonEC2FullAccess"
# }
#######----attach policies------#######
resource "aws_iam_user_policy_attachment" "s3_read_policy" {
  user       = aws_iam_user.user.name
  policy_arn = aws_iam_policy.s3_read.arn
}
resource "aws_iam_user_policy_attachment" "Ec2_full_access" {
  user       = aws_iam_user.user.name
  policy_arn = aws_iam_policy.ec2_full.arn
}






#######----create ec2 instance and attach elastic ip------#######
resource "aws_instance" "ec2_new" {
   ami = "ami-090fa75af13c156b4"
   instance_type = "t2.micro"
   key_name = "ec2"
   tags = {
    Name = "terraform"
  }
}

resource "aws_eip" "myeip" {
  vpc      = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.ec2_new.id
  allocation_id = aws_eip.myeip.id
}






#######----create vpc and subnet 1 private and 1 public------#######
resource "aws_vpc" "main" {
  cidr_block                     = "192.168.0.0/18"
  enable_dns_hostnames           = true
  enable_dns_support             = true
  enable_classiclink_dns_support = true

  tags = {
    Name = "terraform-vpc"
  }
}

 resource "aws_internet_gateway" "IGW" {    
    vpc_id =  aws_vpc.main.id               
 }

### Subnets ###

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-1"
  }
}







#######----create lambda function and attach s3 full access ------#######
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.s3_full.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/hello-python.zip"
}



# resource "aws_lambda_function" "lambda_new" {
#   filename      = "project.zip"
#   function_name = "new-lambda"
#   role = aws_iam_role.lambda_role.arn

#   depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
# }
resource "aws_lambda_function" "terraform_lambda_func" {
  filename                       = "${path.module}/python/hello-python.zip"
  function_name                  = "Lambda_Function"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "index.lambda_handler"
  runtime                        = "python3.8"
  depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}