resource "aws_instance" "test" {
  count = var.enable_test_env ? var.test_instance_count : 0

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
   
  key_name		 = "test"

  subnet_id              = module.vpc.public_subnets[count.index % length(module.vpc.public_subnets)]
  vpc_security_group_ids = [module.ssh_security_group.this_security_group_id,module.lb_security_group.this_security_group_id]
#  user_data = templatefile("${path.module}/init-script.sh", {
#    file_content = "version 1.0 - #${count.index}"
#  })

  tags = {
    Name = "ssh-test-${count.index}"
  }
}

resource "aws_lb_target_group" "ssh" {
  name     = "ssh-tg-${random_pet.app.id}-lb"
  port     = 22
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "ssh" {
  count            = length(aws_instance.test)
  target_group_arn = aws_lb_target_group.ssh.arn
  target_id        = aws_instance.test[count.index].id
  port             = 22
}

resource "aws_lb_target_group" "http-8080" {
  name     = "http-8080-tg-${random_pet.app.id}-lb"
  port     = 8080
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "http-8080" {
  count            = length(aws_instance.test)
  target_group_arn = aws_lb_target_group.http-8080.arn
  target_id        = aws_instance.test[count.index].id
  port             = 8080
}
