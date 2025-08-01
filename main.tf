module "labels" {
  source      = "git@github.com:pankajyadavdevops/terraform-google-labels-.git"
  version     = "1.0.2"
  name        = var.name
  environment = var.environment
  label_order = var.label_order
  managedby   = var.managedby
  repository  = var.repository
  extra_tags  = var.extra_tags
}

data "google_client_config" "current" {
}

#####==============================================================================
##### Each VPC network is subdivided into subnets, and each subnet is contained
##### within a single region. You can have more than one subnet in a region for
##### a given VPC network.
#####==============================================================================
#tfsec:ignore:google-compute-enable-vpc-flow-logs
resource "google_compute_subnetwork" "subnetwork" {
  count         = length(var.subnet_names) > 0 && length(var.ip_cidr_range) > 0 ? min(length(var.subnet_names), length(var.ip_cidr_range)) : 0
  name          = "${var.subnet_names[count.index]}-${module.labels.id}"
  project       = data.google_client_config.current.project
  network       = var.network
  region        = var.region
  description   = var.description
  purpose       = var.purpose
  stack_type    = var.stack_type
  ip_cidr_range = var.ip_cidr_range[count.index]

  # Set ipv6_access_type only if stack_type supports it
  ipv6_access_type = var.stack_type == "IPV4_ONLY" ? null : var.ipv6_access_type

  # Use `private_ip_google_access` and `private_ipv6_google_access` as needed
  private_ip_google_access   = var.private_ip_google_access
  private_ipv6_google_access = var.stack_type == "IPV6_ONLY" ? null : var.private_ipv6_google_access

  dynamic "secondary_ip_range" {
    for_each = contains(keys(var.secondary_ip_ranges), var.subnet_names[count.index]) ? var.secondary_ip_ranges[var.subnet_names[count.index]] : []

    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = var.log_config.enable ? [var.log_config] : []
    content {
      aggregation_interval = var.log_config.aggregation_interval
      flow_sampling        = var.log_config.flow_sampling
      metadata             = var.log_config.metadata
      metadata_fields      = var.log_config.metadata_fields
      filter_expr          = var.log_config.filter_expr
    }
  }

  dynamic "timeouts" {
    for_each = try([var.module_timeouts.google_compute_subnetwork], [])
    content {
      create = try(timeouts.value.create, null)
      update = try(timeouts.value.update, null)
      delete = try(timeouts.value.delete, null)
    }
  }
}

#####==============================================================================
##### Represents a Route resource.
#####==============================================================================
resource "google_compute_route" "default" {
  count = var.enabled && var.route_enabled ? length(var.routes) : 0

  project     = data.google_client_config.current.project
  network     = var.network # This should point to your VPC network
  name        = "${element(keys(var.routes), count.index)}-${module.labels.id}"
  description = lookup(var.routes[element(keys(var.routes), count.index)], "description", null)
  tags        = null #compact([for tag in split(",", lookup(var.routes[element(keys(var.routes), count.index)], "tags", "")) : trimspace(tag) if length(trimspace(tag)) > 0])
  dest_range  = lookup(var.routes[element(keys(var.routes), count.index)], "destination_range", null)

  # Determine next hop based on your requirements
  next_hop_gateway       = lookup(var.routes[element(keys(var.routes), count.index)], "next_hop_internet", "false") == "true" ? "default-internet-gateway" : null
  next_hop_ip            = lookup(var.routes[element(keys(var.routes), count.index)], "next_hop_ip", null)
  next_hop_instance      = lookup(var.routes[element(keys(var.routes), count.index)], "next_hop_instance", null)
  next_hop_instance_zone = lookup(var.routes[element(keys(var.routes), count.index)], "next_hop_instance_zone", null)
  next_hop_vpn_tunnel    = lookup(var.routes[element(keys(var.routes), count.index)], "next_hop_vpn_tunnel", null)
  next_hop_ilb           = lookup(var.routes[element(keys(var.routes), count.index)], "next_hop_ilb", null)

  # Ensure priority is set correctly
  priority = lookup(var.routes[element(keys(var.routes), count.index)], "priority", null)
}

#####==============================================================================
##### Represents a Router resource.
#####==============================================================================
resource "google_compute_router" "default" {
  count   = var.enabled && var.router_enabled ? 1 : 0
  name    = format("%s-router", module.labels.id)
  project = data.google_client_config.current.project
  region  = var.region
  network = var.network

  description = var.description

  bgp {
    asn                = var.asn
    advertise_mode     = var.bgp_advertise_mode
    advertised_groups  = var.bgp_advertised_groups
    keepalive_interval = var.bgp_keepalive_interval

    # Corrected block for advertised_ip_ranges
    dynamic "advertised_ip_ranges" {
      for_each = var.bgp_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }

  encrypted_interconnect_router = var.encrypted_interconnect_router
}

#####==============================================================================
##### Represents an Address resource.
#####==============================================================================
resource "google_compute_address" "default" {
  count        = var.enabled && var.address_enabled ? 1 : 0
  name         = format("%s-address", module.labels.id)
  ip_version   = var.ip_version
  project      = data.google_client_config.current.project
  region       = var.region
  address      = length(var.address) > 0 ? element(var.address, count.index) : null
  address_type = var.address_type
  labels       = var.labels
  description  = try(element(var.description, count.index), null)

  // Remove the network and subnetwork fields for external IPs
  network    = var.address_type == "INTERNAL" ? var.network : null
  subnetwork = var.address_type == "INTERNAL" ? var.subnetwork : null
  purpose    = var.address_type == "INTERNAL" ? var.purpose : null

  // Added fields
  ipv6_endpoint_type = var.ip_version == "IPV6" ? var.ipv6_endpoint_type : null
  network_tier       = var.address_type == "EXTERNAL" ? var.network_tier : null
}

#####==============================================================================
##### A NAT service created in a router.
#####==============================================================================
resource "google_compute_router_nat" "nat" {
  count                  = var.enabled && var.router_nat_enabled ? 1 : 0
  name                   = format("%s-router-nat", module.labels.id)
  router                 = google_compute_router.default[count.index].name
  region                 = var.region
  project                = data.google_client_config.current.project
  nat_ip_allocate_option = var.nat_ip_allocate_option

  # Check if natIpAllocateOption is MANUAL_ONLY to use manual IP assignment
  nat_ips = var.nat_ip_allocate_option == "MANUAL_ONLY" ? [google_compute_address.default[0].self_link] : []

  # Optionally set drain_nat_ips
  drain_nat_ips                      = var.drain_nat_ips
  source_subnetwork_ip_ranges_to_nat = var.source_subnetwork_ip_ranges_to_nat
  udp_idle_timeout_sec               = var.udp_idle_timeout_sec
  icmp_idle_timeout_sec              = var.icmp_idle_timeout_sec
  tcp_established_idle_timeout_sec   = var.tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec    = var.tcp_transitory_idle_timeout_sec
  tcp_time_wait_timeout_sec          = var.tcp_time_wait_timeout_sec

  log_config {
    enable = var.log_enable
    filter = var.log_filter
  }

  dynamic "subnetwork" {
    for_each = var.subnetworks
    content {
      name                     = subnetwork.value.name
      source_ip_ranges_to_nat  = subnetwork.value.source_ip_ranges_to_nat
      secondary_ip_range_names = subnetwork.value.secondary_ip_range_names
    }
  }
}
