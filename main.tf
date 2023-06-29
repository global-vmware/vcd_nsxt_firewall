terraform {
  required_version = "~> 1.2"

  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "~> 3.8"
    }
  }
}

# Create the Datacenter Group data source
data "vcd_vdc_group" "dcgroup" {
  name            = var.vdc_group_name
}

# Create the NSX-T Edge Gateway data source
data "vcd_nsxt_edgegateway" "edge_gateway" {  
  org             = var.vdc_org_name
  owner_id        = data.vcd_vdc_group.dcgroup.id
  name            = var.vdc_edge_name
}

# Create the NSX-T Data Center Edge Gateway Firewall data source
data "vcd_nsxt_firewall" "edge_fw" {
  edge_gateway_id = data.vcd_nsxt_edgegateway.edge_gateway.id
}

data "vcd_nsxt_app_port_profile" "app_port_profiles" {
  for_each = var.app_port_profiles
  name  = each.key
  scope = each.value
}

data "vcd_nsxt_ip_set" "ip_sets" {
  for_each        = toset(var.ip_set_names)
  edge_gateway_id = data.vcd_nsxt_edgegateway.edge_gateway.id
  name            = each.value
}

data "vcd_nsxt_dynamic_security_group" "dynamic_security_groups" {
  for_each      = toset(var.dynamic_security_group_names)
  vdc_group_id  = data.vcd_vdc_group.dcgroup.id
  name          = each.value
}

data "vcd_nsxt_security_group" "security_groups" {
  for_each        = toset(var.security_group_names)
  edge_gateway_id = data.vcd_nsxt_edgegateway.edge_gateway.id
  name            = each.value
}

locals {
  id_lookup = merge(
    { for name, profile in data.vcd_nsxt_app_port_profile.app_port_profiles : name => profile.id },
    { for name, group in data.vcd_nsxt_security_group.security_groups : name => group.id },
    { for name, group in data.vcd_nsxt_dynamic_security_group.dynamic_security_groups : name => group.id },
    { for name, set in data.vcd_nsxt_ip_set.ip_sets : name => set.id }
  )
}

resource "vcd_nsxt_firewall" "edge_firewall" {
  edge_gateway_id = data.vcd_nsxt_edgegateway.edge_gateway.id

  dynamic "rule" {
    for_each = var.rules
    content {
      name                 = rule.value["name"]
      direction            = rule.value["direction"]
      ip_protocol          = rule.value["ip_protocol"]
      action               = rule.value["action"]
      enabled              = lookup(rule.value, "enabled", true)
      logging              = lookup(rule.value, "logging", false)
      source_ids           = try(length(rule.value["source_ids"]), 0) > 0 ? [for name in rule.value["source_ids"]: local.id_lookup[name] if contains(keys(local.id_lookup), name) && name != null && name != ""] : null
      destination_ids      = try(length(rule.value["destination_ids"]), 0) > 0 ? [for name in rule.value["destination_ids"]: local.id_lookup[name] if contains(keys(local.id_lookup), name) && name != null && name != ""] : null
      app_port_profile_ids = try(length(rule.value["app_port_profile_ids"]), 0) > 0 ? [for name in rule.value["app_port_profile_ids"]: local.id_lookup[name] if contains(keys(local.id_lookup), name) && name != null && name != ""] : null
    }
  }
}



