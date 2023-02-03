/**
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
provider "google" {
  project                     = var.project
  impersonate_service_account = "terraform@${var.project}.iam.gserviceaccount.com"
}

module "airship-providers" {
  # version control of the various providers
  source = "github.com/urbanairship/tf-modules-providers?ref=v1"
}

locals {
  labels = merge(var.labels, { "managed_by" : "terraform" })
}

resource "google_redis_instance" "default" {
  project            = var.project
  name               = var.name
  tier               = var.tier
  replica_count      = var.tier == "STANDARD_HA" ? var.replica_count : null
  read_replicas_mode = var.tier == "STANDARD_HA" ? var.read_replicas_mode : null
  memory_size_gb     = var.memory_size_gb
  connect_mode       = var.connect_mode

  region                  = var.region
  location_id             = var.location_id
  alternative_location_id = var.alternative_location_id

  authorized_network   = var.authorized_network
  customer_managed_key = var.customer_managed_key

  redis_version     = var.redis_version
  redis_configs     = var.redis_configs
  display_name      = var.display_name
  reserved_ip_range = var.reserved_ip_range

  persistence_config {
    # Until we have optional parameters this isn't trivial to implement. We also aren't using this.
    persistence_mode = "DISABLED"
  }

  labels = local.labels

  auth_enabled = var.auth_enabled

  transit_encryption_mode = var.transit_encryption_mode

  dynamic "maintenance_policy" {
    for_each = var.maintenance_policy != null ? [var.maintenance_policy] : []
    content {
      weekly_maintenance_window {
        day = maintenance_policy.value["day"]
        start_time {
          hours   = maintenance_policy.value["start_time"]["hours"]
          minutes = maintenance_policy.value["start_time"]["minutes"]
          seconds = maintenance_policy.value["start_time"]["seconds"]
          nanos   = maintenance_policy.value["start_time"]["nanos"]
        }
      }
    }
  }
}
