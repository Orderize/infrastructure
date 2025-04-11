variable "db_username" {
  description = "Usuário admin do banco"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Senha do banco"
  type        = string
  sensitive   = true
}

variable "security_group_id" {
  description = "ID do security group que libera acesso ao RDS"
  type        = string
}
