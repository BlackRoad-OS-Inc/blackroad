variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "name" {
  description = "Worker script name"
  type        = string
}

variable "script_content" {
  description = "Worker script content"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  default     = ""
}

variable "route_pattern" {
  description = "Route pattern for the worker"
  type        = string
  default     = ""
}
