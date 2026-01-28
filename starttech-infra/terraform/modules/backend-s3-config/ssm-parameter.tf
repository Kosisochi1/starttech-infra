resource "aws_ssm_parameter" "port" {
  name  = "/starttech/backend/PORT"
  type  = "String"
  value = "8080"
}

resource "aws_ssm_parameter" "mongo_uri" {
  name  = "/starttech/backend/MONGO_URI"
  type  = "SecureString"
  value = "mongodb+srv://emmanuelezeoyirikosi:Kosionyi3010@cluster0.jnpvxpu.mongodb.net/GO-API"

}

resource "aws_ssm_parameter" "allowed_origins" {
  name  = "/starttech/backend/ALLOWED_ORIGINS"
  type  = "String"
  value = "*"
}
resource "aws_ssm_parameter" "jwt_secret_key" {
  name  = "/starttech/backend/JWT_SECRET_KEY"
  type  = "String"
  value = "your-super-secret-key-that-is-long-and-random"
}
resource "aws_ssm_parameter" "jwt_expiration_hours" {
  name  = "/starttech/backend/JWT_EXPIRATION_HOURS"
  type  = "String"
  value = "72"
}
resource "aws_ssm_parameter" "log_level" {
  name  = "/starttech/backend/LOG_LEVEL"
  type  = "String"
  value = "DEBUG"
}
resource "aws_ssm_parameter" "log_format" {
  name  = "/starttech/backend/LOG_FORMAT"
  type  = "String"
  value = "json"
}
resource "aws_ssm_parameter" "integration" {
  name  = "/starttech/backend/INTEGRATION"
  type  = "String"
  value = true
}
resource "aws_ssm_parameter" "redis_host" {
  name  = "/starttech/backend/REDIS_HOST"
  type  = "String"
  value = "redis-cluster.9tuiin.0001.euw1.cache.amazonaws.com"
}
resource "aws_ssm_parameter" "redis_port" {
  name  = "/starttech/backend/REDIS_PORT"
  type  = "String"
  value = "6379"
}


