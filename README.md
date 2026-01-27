# DODA Project - Team 19

## Architecture
Microservices application with:
- **App (Frontend):** Web UI
- **Model Service (Backend):** Python ML prediction service
- **Lib-Version:** Shared Java library for version awareness

## Repositories
- [Operation](https://github.com/doda25-team19/operation) | [App](https://github.com/doda25-team19/app) | [Model Service](https://github.com/doda25-team19/model-service) | [Lib Version](https://github.com/doda25-team19/lib-version)

---

## Project Documentation
*   [Final Deployment Architecture](docs/deployment.md) - Overview of Istio traffic flow and system components.
*   [Extension Proposal](docs/extension.md) - Proposal for Automated Canary Analysis.

## Assignment 3: Application Deployment & Monitoring

This section details how to deploy the application stack to Kubernetes using Helm and how to access the provisioned monitoring dashboards.

### Prerequisites
- A running Kubernetes cluster as provisioned in Assignment 2.
- The `kubeconfig` for your cluster is configured (e.g., via `export KUBECONFIG=$(pwd)/kubeconfig`).

### 1. Deploying the Application Stack

The `doda-app` Helm chart will deploy the application, Prometheus (for metrics), and Grafana (for dashboards) in one step.

1.  **Navigate to the Helm Chart Directory:**
    ```bash
    cd operation/helm/doda-app
    ```

2.  **Update Helm Dependencies:**
    This command downloads the required dependency charts (like Grafana and Prometheus).
    ```bash
    helm dependency update
    ```

3.  **Create SMTP Secret (for Alertmanager):**
    This secret is required by the Prometheus stack for sending alerts.
    ```bash
    kubectl create secret generic alertmanager-email-secret \
      --from-literal=password="password" \
      -n default
    ```

4.  **Install the Helm Chart:**
    Use `helm install` for the first deployment.
    ```bash
    helm install doda-app-release . -f values.yaml
    ```
    *(If you need to update an existing deployment, use `helm upgrade` instead.)*

    **Custom hostname for grading:**
    ```bash
    helm install doda-app-release . --set hostname="my-grading-url.local"
    ```

### 2. Accessing the Application

#### Frontend Application

1.  **Find the Ingress IP Address:**
    Get the external IP address assigned to the Ingress Controller by MetalLB.
    ```bash
    kubectl get svc -n ingress-nginx
    ```
    *Look for the `EXTERNAL-IP` of the `ingress-nginx-controller` service (e.g., `192.168.56.90`).*

2.  **Update Your Local `/etc/hosts` File:**
    Add the following line to the `hosts` file on your host machine (not the VM).
    ```
    # Replace <EXTERNAL-IP> with the IP from the previous step
    <EXTERNAL-IP> doda-app.local
    ```

3.  **Open in Browser:**
    You can now access the application at **http://doda-app.local**.

**Fallback (port-forward):** `kubectl port-forward svc/app-service 8080:80` then access **http://localhost:8080**

#### Accessing Grafana

1.  **Access via Istio Ingress (recommended):**
  Map the Istio Ingress IP to the Grafana hostname and open it in your browser.
  ```
  # Replace <ISTIO-INGRESS-IP> with the EXTERNAL-IP of istio-ingressgateway
  <ISTIO-INGRESS-IP> grafana.doda-app.local
  ```
  Open **http://grafana.doda-app.local**.

  *Hostname is configurable via `grafanaHostname` in [helm/doda-app/values.yaml](helm/doda-app/values.yaml).* 

2.  **Fallback (port-forward):**
  ```bash
  # This command will continue running. Keep the terminal open.
  kubectl port-forward svc/doda-app-release-grafana 3000:80
  ```
  Then open **http://localhost:3000**.

### 3. Monitoring with Prometheus & Grafana

#### Automatic Dashboard Provisioning
The Helm chart is configured to **automatically provision** the required Grafana dashboards. **No manual import is needed.**

Two dashboards are included in the `helm/doda-app/dashboards/` directory:
-   `dashboard-overview.json`: An overview of all application metrics.
-   `dashboard-a4.json`: Supports the A4 experiment analysis.

*Technical Note: During installation, these JSON files are packaged into a `ConfigMap` with the label `grafana_dashboard: "1"`. The Grafana sidecar automatically detects this label and loads the dashboards on startup.*

### 4. Verifying "Excellent" Grade Criteria

Run these commands to verify that the Kubernetes usage requirements have been met.

#### ConfigMap & Secret Injection
1.  **Get the App Pod Name:**
    ```bash
    APP_POD=$(kubectl get pod -l app=app-service -o jsonpath="{.items[0].metadata.name}")
    ```
2.  **Check for Injected Environment Variables:**
    ```bash
    kubectl describe pod $APP_POD | grep -A5 "Environment:"
    ```
    *The output should show environment variables mounted from `doda-app-release-configmap` and `doda-app-release-secret`.*

#### HostPath Volume Mount
1.  **Get the Model Service Pod Name:**
    ```bash
    MODEL_POD=$(kubectl get pod -l app=model-service -o jsonpath="{.items[0].metadata.name}")
    ```
2.  **Check for Volume Mounts:**
    ```bash
    kubectl describe pod $MODEL_POD | grep -A5 "Mounts:"
    ```
    *The output should show the `/data/shared` path is mounted from the `shared-data-volume`.*

---

### 5. Local Development with Minikube & Troubleshooting (Optional)

If you are testing locally without the A2 cluster or are facing networking issues on macOS, you can use Minikube.

1.  **Setup Minikube:**
    ```bash
    # Start Minikube (use docker driver on macOS for better networking)
    minikube start --driver=docker

    # Enable the ingress addon
    minikube addons enable ingress
    ```

2.  **Deploy the application using Helm:**
    Follow the steps in **Assignment 3 – Deploying the Application Stack**

3.  **Test Connectivity (Minikube on macOS):**

    Due to Docker networking, you must use `minikube service` to get a temporary URL.
    ```bash
    minikube service -n ingress-nginx ingress-nginx-controller --url
    ```
    Use the HTTP URL provided by the command to test with `curl`:
    ```bash
    # Replace the URL with the one from the previous command
    curl -H "Host: doda-app.local" http://127.0.0.1:XXXXX
    curl -H "Host: metrics.doda-app.local" http://127.0.0.1:XXXXX/metrics
    ```

---

### 6. Istio Rate Limiting

Global rate limiting is enforced at the Istio IngressGateway via EnvoyFilter with a token bucket algorithm. All traffic to `/sms` shares a single token bucket. When the bucket is exhausted, responses return HTTP 429.

**Quick test (burst):**
```bash
for i in {1..20}; do
  curl -X POST http://doda-app.local/sms/ \
    -H "Content-Type: application/json" \
    -d '{"sms":"test message"}' \
    -w "\nStatus: %{http_code}\n"
done
```

**Expected result:** You will see a mix of HTTP 200 and 429 responses once the bucket is exhausted (token refill timing makes the order non-deterministic).

**Config:**
Edit `helm/doda-app/values.yaml` → `istio.rateLimiting.burstSize` and `fillInterval`, then:
```bash
cd helm/doda-app
helm upgrade doda-app . -f values.yaml
```

**Disable:** set `istio.rateLimiting.enabled: false` and upgrade.


## Assignment 2: Provisioning a Kubernetes Cluster
We have implemented a fully automated provisioning setup using Vagrant and Ansible to deploy a Kubernetes cluster.

### Prerequisites
- Vagrant 2.4+
- VirtualBox 7.0+ (or VMware for macOS)
- Ansible

### How to Run the Cluster Provisioning

**1. Provision the Infrastructure:**
This command will create one controller and one/two worker VMs. It also automatically runs the initial Ansible playbooks (`general.yaml` and `ctrl.yaml`) to set up the base environment and the Kubernetes controller.

```bash
vagrant up
```

**2. Join Worker Nodes to the Cluster:**
This is the first manual step. It runs the `node.yaml` playbook, which makes the worker nodes securely join the controller.

```bash 
ansible-playbook -i inventory.cfg node.yaml
```

Run these in order from the operation directory if needed:
```bash

ansible-playbook -i inventory.cfg general.yaml
ansible-playbook -i inventory.cfg ctrl.yaml
ansible-playbook -i inventory.cfg node.yaml
```

**3. Finalize the Cluster (Install MetalLB):**
This is the second manual step. It runs the `finalization.yml` playbook to install and configure the MetalLB network load balancer.

```bash
ansible-playbook -i inventory.cfg finalization.yml
```

### How to Access the Cluster

**Required host entries**

To access the application and the Kubernetes dashboard through the Nginx ingress controller you must add the following entries to your host machine’s hosts file.

On macOS and Linux the file is at `/etc/hosts`

```bash
192.168.56.90  doda-app.local
192.168.56.90  dashboard.local
```

These hostnames are used by the ingress rules deployed in the cluster.

The `kubeconfig` file (your cluster credentials) is available in the `operation` directory. To use `kubectl` from your host machine, you can either use the `--kubeconfig` flag or export the environment variable.

```bash
export KUBECONFIG=$(pwd)/kubeconfig
# Now you can run kubectl commands directly
kubectl get nodes
kubectl get pods -A
```

### Access the Kubernetes Dashboard

1. Add the host entry (on your host machine):
  ```
  192.168.56.90  dashboard.local
  ```
2. Open https://dashboard.local in your browser.
3. Generate a login token:
  ```bash
  kubectl -n kubernetes-dashboard create token admin-user
  ```

---
### Post-Provisioning Steps

After running `finalization.yml` the following components are installed and configured automatically
- MetalLB
- Nginx ingress controller
- Kubernetes dashboard with an admin user and ingress
- Istio using the demo profile

#### Deploy the Application

The ingress controller is already installed automatically.
To deploy the application services apply the manifests in the `k8s` folder.

```bash
kubectl apply -f k8s/model-service-deployment.yaml
kubectl apply -f k8s/model-service-service.yaml
kubectl apply -f k8s/app-service-deployment.yaml
kubectl apply -f k8s/app-service-service.yaml
kubectl apply -f k8s/ingress.yaml
```

## Assignment 1: Containerization
In this assignment, we have successfully reorganized the SMS Checker project into 4 repositories:
**model-service**
**lib-version**
**app**
**operation**

We have implemented all features required, extended the application and started maturing the release engineering practices.

### How to Run (Local Docker)
To run the application containerized locally without Kubernetes:
```bash
docker-compose up
```

To access the frontend, open your browser at **http://localhost:8080/sms**