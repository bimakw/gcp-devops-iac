# Copyright (c) 2024 Bima Kharisma Wicaksana
# TFLint Configuration for GCP Terraform

config {
  # Enable module inspection (call_module_type replaces deprecated 'module' in v0.54+)
  call_module_type = "all"

  # Force to return error code when issues found
  force = false
}

# Google Cloud Provider Plugin
plugin "google" {
  enabled = true
  version = "0.27.1"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

# Terraform Language Rules
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# ============================================
# Terraform Best Practices Rules
# ============================================

# Disallow legacy dot index syntax
rule "terraform_deprecated_index" {
  enabled = true
}

# Disallow deprecated interpolation syntax
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Disallow output without description
rule "terraform_documented_outputs" {
  enabled = true
}

# Disallow variable without description
rule "terraform_documented_variables" {
  enabled = true
}

# Disallow // comments
rule "terraform_comment_syntax" {
  enabled = true
}

# Enforce naming conventions
rule "terraform_naming_convention" {
  enabled = true

  # Use snake_case for all names
  variable {
    format = "snake_case"
  }

  locals {
    format = "snake_case"
  }

  output {
    format = "snake_case"
  }

  resource {
    format = "snake_case"
  }

  module {
    format = "snake_case"
  }

  data {
    format = "snake_case"
  }
}

# Require type declarations for variables
rule "terraform_typed_variables" {
  enabled = true
}

# Disallow unused declarations
rule "terraform_unused_declarations" {
  enabled = true
}

# Disallow unused required providers
rule "terraform_unused_required_providers" {
  enabled = true
}

# Enforce workspace naming
rule "terraform_workspace_remote" {
  enabled = true
}

# ============================================
# GCP Specific Rules
# ============================================

# Warn about invalid machine types
rule "google_compute_instance_invalid_machine_type" {
  enabled = true
}

# Warn about invalid disk types
rule "google_compute_disk_invalid_type" {
  enabled = true
}

# Warn about invalid regions
rule "google_project_iam_member_invalid_member" {
  enabled = true
}
