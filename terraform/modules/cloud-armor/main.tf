/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Cloud Armor (WAF) Module
 * Web Application Firewall for DDoS protection and security
 */

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

# Security Policy
resource "google_compute_security_policy" "policy" {
  name        = "${var.project_name}-security-policy-${var.environment}"
  project     = var.project_id
  description = "Cloud Armor security policy for ${var.project_name} (${var.environment})"

  # Default rule - allow all (lowest priority)
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }

  # OWASP Top 10 Protection Rules
  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_action
      priority = 1000
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
        }
      }
      description = "XSS protection"
    }
  }

  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_action
      priority = 1001
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
        }
      }
      description = "SQL injection protection"
    }
  }

  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_action
      priority = 1002
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('lfi-v33-stable')"
        }
      }
      description = "Local file inclusion protection"
    }
  }

  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_action
      priority = 1003
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('rfi-v33-stable')"
        }
      }
      description = "Remote file inclusion protection"
    }
  }

  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_action
      priority = 1004
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('rce-v33-stable')"
        }
      }
      description = "Remote code execution protection"
    }
  }

  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_action
      priority = 1005
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('scannerdetection-v33-stable')"
        }
      }
      description = "Scanner detection"
    }
  }

  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_action
      priority = 1006
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('protocolattack-v33-stable')"
        }
      }
      description = "Protocol attack protection"
    }
  }

  dynamic "rule" {
    for_each = var.enable_owasp_rules ? [1] : []
    content {
      action   = var.owasp_action
      priority = 1007
      match {
        expr {
          expression = "evaluatePreconfiguredExpr('sessionfixation-v33-stable')"
        }
      }
      description = "Session fixation protection"
    }
  }

  # Rate Limiting Rule
  dynamic "rule" {
    for_each = var.enable_rate_limiting ? [1] : []
    content {
      action   = "rate_based_ban"
      priority = 100

      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = ["*"]
        }
      }

      rate_limit_options {
        conform_action = "allow"
        exceed_action  = "deny(429)"
        enforce_on_key = "IP"

        rate_limit_threshold {
          count        = var.rate_limit_requests_per_interval
          interval_sec = var.rate_limit_interval_sec
        }

        ban_duration_sec = var.rate_limit_ban_duration_sec

        ban_threshold {
          count        = var.rate_limit_ban_threshold_count
          interval_sec = var.rate_limit_ban_threshold_interval_sec
        }
      }

      description = "Rate limiting - ${var.rate_limit_requests_per_interval} requests per ${var.rate_limit_interval_sec}s"
    }
  }

  # Geo-blocking Rules
  dynamic "rule" {
    for_each = length(var.blocked_countries) > 0 ? [1] : []
    content {
      action   = "deny(403)"
      priority = 200

      match {
        expr {
          expression = "origin.region_code in [${join(",", formatlist("'%s'", var.blocked_countries))}]"
        }
      }

      description = "Block traffic from specified countries"
    }
  }

  # IP Allowlist (highest priority for trusted IPs)
  dynamic "rule" {
    for_each = length(var.allowlist_ips) > 0 ? [1] : []
    content {
      action   = "allow"
      priority = 10

      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.allowlist_ips
        }
      }

      description = "Allowlist trusted IPs"
    }
  }

  # IP Blocklist
  dynamic "rule" {
    for_each = length(var.blocklist_ips) > 0 ? [1] : []
    content {
      action   = "deny(403)"
      priority = 50

      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.blocklist_ips
        }
      }

      description = "Block malicious IPs"
    }
  }

  # Adaptive Protection (requires Cloud Armor Plus)
  dynamic "adaptive_protection_config" {
    for_each = var.enable_adaptive_protection ? [1] : []
    content {
      layer_7_ddos_defense_config {
        enable          = true
        rule_visibility = "STANDARD"
      }
    }
  }
}
