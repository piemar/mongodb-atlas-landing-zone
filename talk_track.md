# 🎤 MongoDB Atlas "Golden Path" Demo - Talk Track

**Goal:** Demonstrate how Svenska Spel can automate secure, compliant MongoDB Atlas infrastructure using Terraform, Kubernetes, and Backstage.

---

## 🎬 Scene 1: The "Golden Path" (Backstage)
**Context:** You are a Developer wanting a database. You don't want to learn Terraform or open tickets.

1.  **Open Backstage Template** (`backstage/atlas-template.yaml`):
    *   *"As a developer, I just want a database. I go to our Internal Developer Portal."*
    *   *"I select 'Create MongoDB Atlas Cluster'."*
2.  **Show the Form:**
    *   *"I fill in the basics: Project Name, Region (Finland), and T-Shirt Size."*
    *   *"Notice I can't choose insecure options. The platform team has baked in the guardrails."*
3.  **The Result (The PR):**
    *   *"When I click create, it doesn't just magically appear. It creates a **Pull Request** with Terraform code."*
    *   *"This gives us GitOps: Version control, Peer Review, and Audit trails."*

---

## 🎬 Scene 2: The Infrastructure (Terraform)
**Context:** You are now the Platform Engineer reviewing what happened under the hood.

1.  **Show `terraform/main.tf`:**
    *   *"This is the code that Backstage generated (based on our Skeleton)."*
    *   *"It's modular. We have a `foundation` module for the project, `cluster` for the database, and `security` for access."*
2.  **Highlight Security:**
    *   *"We are NOT creating a user with `password123`."*
    *   *"We are using **Workload Identity Federation** (or K8s Secrets) to automate authentication."*

---

## 🎬 Scene 3: The Application (Kubernetes)
**Context:** The infrastructure is ready. Now we deploy the app.

1.  **Show `kubernetes/app-deployment.yaml`:**
    *   *"Here is our Payment Service running in GKE Autopilot."*
    *   *"Look at the `env` section. We are NOT hardcoding the connection string."*
    *   *"We inject it from a Kubernetes Secret (`atlas-creds`) that Terraform automatically created."*
2.  **Deploy & Verify:**
    *   *"Let's deploy it."* (`kubectl apply -f kubernetes/app-deployment.yaml`)
    *   *"Now I'll open the app."* (Open the External IP).
3.  **The "Magic" Moment:**
    *   *"I click 'Log In'. The app connects to Atlas."*
    *   *"Success! We just went from 'I need a DB' to a running, secure app without ever handling a password manually."*

---

## 🧠 Key Takeaways for Svenska Spel
1.  **Self-Service:** Developers move fast.
2.  **Compliance:** Security is automated (Private Endpoints, Auditing, WIF).
3.  **Standardization:** Everyone uses the same "Golden Path" modules.
