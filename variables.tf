variable "vdc_org_name" {}

variable "vdc_group_name" {}

variable "vdc_edge_name" {}

variable "app_port_profiles" {
  description = "Map of app port profiles with their corresponding scopes"
  type = map(string)
  default = {}
}

variable "ip_set_names" {
  type = list(string)
  default = []
}

variable "dynamic_security_group_names" {
  type = list(string)
  default = []
}

variable "security_group_names" {
  type = list(string)
  default = []
}

variable "rules" {
  description = "List of rules to apply"
  type = list(object({
    name                 = string
    direction            = string
    ip_protocol          = string
    action               = string
    enabled              = optional(bool)
    logging              = optional(bool)
    source_ids           = optional(list(string))
    destination_ids      = optional(list(string))
    app_port_profile_ids = optional(list(string))
  }))
  default = []
}
