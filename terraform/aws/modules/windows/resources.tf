data "aws_availability_zones" "available" {}

data "aws_ami" "windows_ami" {
  count = length(var.windows_servers)
  most_recent = true
  owners      = ["801119661308"] # Canonical

  filter {
    name   = "name"
    values = [var.windows_servers[count.index].windows_ami]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "windows_server" {
  count = length(var.windows_servers)
  ami = data.aws_ami.windows_ami[count.index].id
  instance_type = (var.zeek_server.zeek_server == "1" || var.snort_server.snort_server == "1") ? "m5.2xlarge" : "t3.xlarge"
  key_name = var.general.key_name
  subnet_id = var.ec2_subnet_id
  private_ip = "10.0.1.${14 + count.index}"
  vpc_security_group_ids = [var.vpc_security_group_ids]
  associate_public_ip_address = true
  tags = {
    Name = "ar-win-${var.general.key_name}-${var.general.attack_range_name}-${count.index}"
  }
  user_data = <<EOF
<powershell>
$admin = [adsi]("WinNT://./Administrator, user")
$admin.PSBase.Invoke("SetPassword", "${var.general.attack_range_password}")
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
net stop winrm
sc.exe config winrm start=auto
net start winrm
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-PSRemoting -SkipNetworkProfileCheck -Force
# Variable specifying the drive you want to extend
$drive_letter = "C"
# Script to get the partition sizes and then resize the volume
$size = (Get-PartitionSupportedSize -DriveLetter $drive_letter)
Resize-Partition -DriveLetter $drive_letter -Size $size.SizeMax
</powershell>
EOF

  root_block_device {
    delete_on_termination = true
    volume_size           = 50
  }

  provisioner "remote-exec" {
    inline = [
      "echo booted"
      ]

    connection {
      type     = "winrm"
      user     = "Administrator"
      #password = "${rsadecrypt(aws_instance.windows_server[count.index].password_data, file(var.aws.private_key_path))}"
      password = var.general.attack_range_password
      host     = self.public_ip
      port     = 5985
      insecure = true
      https    = false
      timeout  = "20m"
    }
  }

  provisioner "local-exec" {
    working_dir = "../ansible"
    command = <<-EOT
      cat <<EOF > vars/windows_vars_${count.index}.json
      {
        "ansible_user": "Administrator",
        "ansible_password": ${var.general.attack_range_password},
        "attack_range_password": ${var.general.attack_range_password},
        "general": ${jsonencode(var.general)},
        "splunk_server": ${jsonencode(var.splunk_server)},
        "simulation": ${jsonencode(var.simulation)},
        "windows_servers": ${jsonencode(var.windows_servers[count.index])},
        "caldera_server": ${jsonencode(var.caldera_server)},
      }
      EOF
    EOT
  }

  provisioner "local-exec" {
    working_dir = "../ansible"
    command = "ansible-playbook -i '${self.public_ip},' windows.yml -e @vars/windows_vars_${count.index}.json"
  }

}

resource "aws_eip" "windows_ip" {
  count = (var.aws.use_elastic_ips == "1") ? length(var.windows_servers) : 0
  instance = aws_instance.windows_server[count.index].id
}
