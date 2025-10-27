// discovery.tfquery.hcl
list "aws_instance" "unmanaged_web" {
  provider = aws
  config {
    filter {
      name = "tag:Purpose"
      values = ["web-server"]
    }  
  }
}
