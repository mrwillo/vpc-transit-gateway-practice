variable "vpc_cidrs" {
    type = list
    default = [
        "10.0.0.0/16",
        "10.1.0.0/16",
        # "10.2.0.0/16"
    ]
}

variable "subnet_cidrs" {
    type = list
    default = [
        ["10.0.101.0/24","10.0.102.0/24"],//,"10.0.103.0/24"], 
        ["10.1.101.0/24","10.1.102.0/24"],//"10.1.103.0/24"], 
        ["10.2.101.0/24","10.2.102.0/24"],//"10.2.103.0/24"]
    ]
}

variable "additional_tags" {
    type = map(string)
    default = {
      "created_by" = "terraform"
    }
}