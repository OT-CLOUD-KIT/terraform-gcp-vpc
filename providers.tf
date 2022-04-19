provider "google" {
  credentials = file("service-account.json")
  project     = "pawan-346205"
  region      = "us-central1"
}