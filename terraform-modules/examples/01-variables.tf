variable "project_name" {
  description = "Project name"
  type        = string
  default     = "contoso"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Primary Azure location"
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Secondary Azure location"
  type        = string
  default     = "westus2"
}

variable "admin_group_ids" {
  description = "Azure AD admin group IDs for AKS"
  type        = list(string)
  default     = []
  # Example: ["00000000-0000-0000-0000-000000000001"]
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed for ACR network access"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for monitoring"
  type        = string
  default     = ""
}
