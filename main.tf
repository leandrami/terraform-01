# Configuração do Provider para apontar para o LocalStack
provider "aws" {
 access_key                  = "test"
 secret_key                  = "test"
 region                      = "us-east-1"
 s3_use_path_style           = true
 skip_credentials_validation = true
 skip_metadata_api_check     = true
 skip_requesting_account_id  = true
 endpoints {
   s3 = "http://s3.localhost.localstack.cloud:4566"
 }
}

# Definição dos nomes dos buckets para os 3 Front-Ends
locals {
 frontends = [
   "app-frontend-vendas",
   "app-frontend-admin",
   "app-frontend-cliente"
 ]
}

# Criação dos Buckets S3
resource "aws_s3_bucket" "frontend_buckets" {
 count  = length(local.frontends)
 bucket = local.frontends[count.index]
}

# Configuração de hospedagem de site estático
resource "aws_s3_bucket_website_configuration" "frontend_website" {
 count  = length(local.frontends)
 bucket = aws_s3_bucket.frontend_buckets[count.index].id
 index_document {
   suffix = "index.html"
 }
}


# Upload automático de todos os arquivos para todos os buckets
resource "aws_s3_object" "frontend_files" {
  for_each = {
    for pair in setproduct(local.frontends, ["index.html", "style.css", "script.js"]) :
    "${pair[0]}_${pair[1]}" => {
      bucket = pair[0]
      file   = pair[1]
    }
  }

  bucket       = each.value.bucket
  key          = each.value.file
  source       = each.value.file
  content_type = each.value.file == "index.html" ? "text/html" : (each.value.file == "style.css" ? "text/css" : "application/javascript")
}