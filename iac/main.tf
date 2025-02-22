resource "google_project_service" "apis_activation" {
  for_each = toset(local.all_needed_apis)
  project  = "sandbox-sviguier"
  service  = each.key
}

# Cloud SQL Instance
resource "google_sql_database_instance" "instance" {
  count            = var.database_choosed.sql ? 1 : 0
  name             = "fastapi-template-instance"
  project          = "sandbox-sviguier"
  region           = "europe-west1"
  database_version = "POSTGRES_15"
  settings {
    tier = "db-f1-micro"
  }

  deletion_protection = "false"

  depends_on = [google_project_service.apis_activation]
}

# Cloud SQL Database
resource "google_sql_database" "database" {
  count    = var.database_choosed.sql ? 1 : 0
  name     = "fastapi_template_db"
  instance = google_sql_database_instance.instance[0].name
}

# Cloud SQL postgres user
resource "google_sql_user" "app_user" {
  count    = var.database_choosed.sql ? 1 : 0
  name     = "fastapi-template-user"
  instance = google_sql_database_instance.instance[0].name
  password = "password"
}

# Firestore instance
resource "google_firestore_database" "database" {
  count       = var.database_choosed.firestore ? 1 : 0
  project     = "sandbox-sviguier"
  name        = "fastapi-template"
  location_id = "eur3"
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.apis_activation]
}

# Firestore doc exemple
resource "google_firestore_document" "user_doc_exemple" {
  count       = var.database_choosed.firestore ? 1 : 0
  project     = "sandbox-sviguier"
  database    = google_firestore_database.database[0].name
  collection  = "Users"
  document_id = "jean.dupont@gmail.com"
  fields = jsonencode({
    "created_at" = { timestampValue = timestamp() }, // Replace with actual creation timestamp
    "updated_at" = { timestampValue = timestamp() }, // Replace with actual update timestamp
    "first_name" = { stringValue = "Jean" },
    "last_name"  = { stringValue = "Dupont" },
    "email"      = { stringValue = "jean.dupont@gmail.com" },
  })
  lifecycle {
    ignore_changes = [
      fields
    ]
  }
}


# Cloud run service
resource "google_cloud_run_service" "backend_service" {
  name     = "fastapi-template"
  location = "europe-west1"

  template {
    spec {
      containers {
        env {
          name  = "PROJECT_ID"
          value = "sandbox-sviguier"
        }
        # Image is pushed by Cloud Build before
        image = "europe-docker.pkg.dev/sandbox-sviguier/fastapi-template-repository/fastapi-template"
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "1000"
        "run.googleapis.com/cloudsql-instances" = var.database_choosed.sql ? google_sql_database_instance.instance[0].connection_name : ""
        "run.googleapis.com/client-name"        = "terraform"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
  lifecycle {
    ignore_changes = [
      template.0.metadata.0.annotations,
    ]
  }

  depends_on = [google_project_service.apis_activation]
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.backend_service.location
  project  = google_cloud_run_service.backend_service.project
  service  = google_cloud_run_service.backend_service.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
