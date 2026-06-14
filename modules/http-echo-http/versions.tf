terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
      # >= 3.4 for the retry {} block (so a flaky echo host does not fail apply).
      version = ">= 3.4"
    }
  }
}
