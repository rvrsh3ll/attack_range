variable "general" {
    type = map(string)

    default = {
        attack_range_password = "Pl3ase-k1Ll-me:p"
        key_name = "attack-range-key-pair"
        ip_whitelist = "0.0.0.0/0"
    }
}

variable "aws" {
    type = map(string)

    default = {
        region = "eu-central-1"
        private_key_path = "~/.ssh/id_rsa"
        image_owner = "591511147606"
    }
}

variable "splunk_server" {
    type = map(string)

    default = {
        install_es = "0"
        splunk_es_app = "splunk-enterprise-security_701.spl"
    }
}

variable "phantom_server" {
    type = map(string)

    default = {
        phantom_server = "0"
        phantom_community_username = "user"
        phantom_community_password = "password"
        phantom_repo_url = "https://repo.phantom.us/phantom/5.2/base/7/x86_64/phantom_repo-5.2.1.78411-1.x86_64.rpm"
        phantom_version = "5.2.1.78411-1"
    }
}

variable "windows_servers" {
  type = list

  default = [
    {
        hostname = "ar-win"
        image = "windows-2016-2-0-0"
        win_sysmon_config = "SwiftOnSecurity.xml"
        create_domain = "0"
        join_domain = "0"
        install_red_team_tools = "0"
        install_caldera_agent = "0"
    }
  ]
}

variable "linux_servers" {
  type = list

  default = [
    {
        hostname = "ar-linux"
        image = "ubuntu-18-04-v2-0-0"
        sysmon_config = "configs/SwiftOnSecurity.xml"
        install_caldera_agent = "0"
    }
  ]
}

variable "simulation" { }

variable "kali_server" {
    type = map(string)

    default = {
      "kali_server" = "0"
    }
}

variable "nginx_server" {
    type = map(string)

    default = {
        nginx_server = "0"
        image = "nginx-web-proxy-v2-0-0"
        proxy_server_ip = "10.0.1.12"
        proxy_server_port = "8000"
    }
}

variable "zeek_server" { }

variable "snort_server" { }

variable "caldera_server" {
    type = map(string)

    default = {
        "caldera_server" = "0"
    }
}