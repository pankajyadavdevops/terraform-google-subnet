# Outputs for google_compute_subnetwork
output "subnet_id" {
  description = "The ID of the GCP subnetwork."
  value       = join("", google_compute_subnetwork.subnetwork[*].id)
}

output "subnet_name" {
  description = "The name of the GCP subnetwork."
  value       = join("", google_compute_subnetwork.subnetwork[*].name)
}

output "subnet_creation_timestamp" {
  description = "The timestamp when the GCP subnetwork was created."
  value       = join("", google_compute_subnetwork.subnetwork[*].creation_timestamp)
}

output "subnet_gateway_address" {
  description = "The gateway address of the GCP subnetwork."
  value       = join("", google_compute_subnetwork.subnetwork[*].gateway_address)
}

output "subnet_ipv6_cidr_range" {
  description = "The IPv6 CIDR range of the GCP subnetwork."
  value       = join("", google_compute_subnetwork.subnetwork[*].ipv6_cidr_range)
}

output "subnet_external_ipv6_prefix" {
  description = "The external IPv6 prefix of the GCP subnetwork."
  value       = join("", google_compute_subnetwork.subnetwork[*].external_ipv6_prefix)
}

output "subnet_self_link" {
  description = "The self-link of the GCP subnetwork."
  value       = join("", google_compute_subnetwork.subnetwork[*].self_link)
}

# Outputs for google_compute_route
output "route_id" {
  description = "The name of the GCP route."
  value       = [for r in google_compute_route.default : r.name]
}

output "route_next_hop_network" {
  description = "The next hop network of the GCP route."
  value       = [for r in google_compute_route.default : r.next_hop_gateway]
}

output "route_self_link" {
  description = "The self-link of the GCP route."
  value       = [for r in google_compute_route.default : r.self_link]
}

# Outputs for google_compute_router
output "router_id" {
  description = "The ID of the GCP router."
  value       = [for r in google_compute_router.default : r.id]
}

output "router_creation_timestamp" {
  description = "The timestamp when the GCP router was created."
  value       = join("", google_compute_router.default[*].creation_timestamp)
}

output "router_self_link" {
  description = "The self-link of the GCP router."
  value       = join("", google_compute_router.default[*].self_link)
}

# Outputs for google_compute_address
output "address_name" {
  description = "The name of the GCP address."
  value       = join("", google_compute_address.default[*].name)
}

output "address_project" {
  description = "The project of the GCP address."
  value       = join("", google_compute_address.default[*].project)
}

output "address_region" {
  description = "The region of the GCP address."
  value       = join("", google_compute_address.default[*].region)
}

output "address_id" {
  description = "The ID of the GCP address in the format: projects/{{project}}/regions/{{region}}/addresses/{{name}}"
  value       = join("", google_compute_address.default[*].id)
}

output "address_self_link" {
  description = "The self_link of the GCP address resource."
  value       = join("", google_compute_address.default[*].self_link)
}

output "address_users" {
  description = "The resources using this address."
  value       = join("", google_compute_address.default[0].users)
}

output "address_label_fingerprint" {
  description = "The fingerprint used for optimistic locking."
  value       = join("", google_compute_address.default[*].label_fingerprint)
}

output "address_terraform_labels" {
  description = "Labels that are directly configured on the resource, including default labels."
  value       = join(", ", [for k, v in google_compute_address.default[0].terraform_labels : "${k}=${v}"])
}

output "address_effective_labels" {
  description = "All labels (key/value pairs) currently applied to the resource."
  value       = join(", ", [for k, v in google_compute_address.default[0].effective_labels : "${k}=${v}"])
}

output "address_creation_timestamp" {
  description = "Creation timestamp of the GCP address in RFC3339 format."
  value       = join("", google_compute_address.default[*].creation_timestamp)
}

# Outputs for google_compute_router_nat
output "router_nat_id" {
  description = "The project of the GCP router NAT configuration."
  value       = join("", google_compute_router_nat.nat[*].id)
}

output "router_nat_name" {
  description = "The name of the GCP router NAT configuration."
  value       = join("", google_compute_router_nat.nat[*].name)
}

output "router_nat_router" {
  description = "The router associated with the GCP router NAT configuration."
  value       = join("", google_compute_router_nat.nat[*].router)
}

output "router_nat_region" {
  description = "The region of the GCP router NAT configuration."
  value       = join("", google_compute_router_nat.nat[*].region)
}