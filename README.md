# MongoDB Atlas Workshop - Demo Assets

This repository contains all the technical assets, scripts, and documentation for the MongoDB Atlas Workshop (Dec 16th).

## 📋 Prerequisites

Before the workshop, ensure you have the following prepared:

1.  **MongoDB Atlas Account:**
    *   Access to an Atlas Organization with "Organization Owner" or "Project Creator" permissions.
    *   **API Keys:** Create a Public/Private API Key pair at the Organization level.
        *   *Permissions:* Organization Owner (required for creating Projects).
        *   *Allowlist:* Add your current IP address.

2.  **Google Cloud Platform (GCP):**
    *   A GCP Project to host the Private Endpoint and Service Accounts.
    *   `gcloud` CLI installed and authenticated.

3.  **Tools:**
    *   [Terraform](https://developer.hashicorp.com/terraform/install) (v1.0+)
    *   [kubectl](https://kubernetes.io/docs/tasks/tools/) (Optional, for K8s demo)

## 🚀 Quick Start

### 1. Automated Setup (Recommended)
Run the helper script to check tools and configure credentials:

```bash
cd scripts
./setup.sh
source .env
```

### 2. Manual Setup
If you prefer to configure manually:
Export your Atlas API keys as environment variables to avoid hardcoding them:

```bash
export TF_VAR_atlas_public_key="your_public_key"
export TF_VAR_atlas_private_key="your_private_key"
export TF_VAR_atlas_org_id="your_org_id"
export TF_VAR_gcp_project_id="your_gcp_project_id"
export GITHUB_TOKEN="your_github_token" # Required for Backstage Scaffolder
```

### 3. Terraform Demo ("Part-by-Part")
The Terraform code is designed to be uncommented in stages.

1.  Navigate to the directory:
    ```bash
    cd terraform
    ```
2.  Initialize Terraform:
    ```bash
    terraform init
    ```
3.  **Part 1 (Foundation):** Run `terraform apply`. This creates the Project.
4.  **Part 2 (Cluster):** Uncomment the `module "cluster"` block in `main.tf` and run `terraform apply`.
5.  **Part 3 (Security):** Uncomment `module "security"` and apply.
6.  **Part 4 (Advanced):** Uncomment `module "advanced"` and apply.
7.  **Part 5 (Integrations):** Uncomment `module "integrations"` and apply.
8.  **Part 6 (Sharding):** Uncomment `module "sharding"` and apply.

### 3. Backstage Demo (The "Golden Path")
Since we don't have a live Backstage instance, you will demonstrate the **Code & Process**:

1.  **Show the Template (`backstage/atlas-template.yaml`):**
    *   Explain that this file defines the UI form developers see in Backstage.
    *   Highlight the `parameters` section (Name, Region, Size) - this is how you enforce governance (e.g., only allowing specific regions).
    *   Show the `steps` section - specifically `fetch:template` and `publish:github:pull-request`.

2.  **Show the mongodb-atlas-landingzone (`backstage/mongodb-atlas-template/`):**
    *   Explain that this is the "Cookie Cutter" code.
    *   Open `main.tf` and show how variables like `var.project_name` are injected.
    *   Point out the "Best Practices" hardcoded here (e.g., `termination_protection`, `backup_enabled`) that developers get for free.

3.  **The Story:**
    *   "Developers don't write Terraform from scratch."
    *   "They fill out a form, Backstage creates a PR with this high-quality Terraform code."
    *   "Platform Engineers review the PR, merge it, and Atlantis/Terraform Cloud applies it."

### 4. Kubernetes Demo (The "Golden Path")
This is the core of the technical demo. It shows the end-to-end flow from Infrastructure to Application.

1.  **Provision Infrastructure:**
    ```bash
    cd terraform
    terraform apply
    ```
    *   This creates the GKE Cluster, Atlas Cluster, and the **Kubernetes Secret** (`atlas-creds`) containing the database credentials.

2.  **Deploy Application:**
    ```bash
    # Ensure you are in the project root
    cd .. 
    
    # Authenticate kubectl (if needed)
    gcloud container clusters get-credentials atlas-demo-cluster --region europe-north1 --project svenska-spel-demo
    
    # Deploy
    kubectl apply -f kubernetes/app-deployment.yaml
    ```

3.  **Verify:**
    *   Get the External IP: `kubectl get service my-app-service`
    *   Open in Browser.
    *   Click "Log In" to verify the secure connection to MongoDB Atlas.

## 📚 Documentation
*   **`talk_track.md`**: **START HERE.** The script for presenting this demo.
# mongodb-atlas-landing-zone
