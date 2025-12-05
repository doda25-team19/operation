# DODA Project - Team 19

## Architecture
The application consists of a microservices architecture:
1.  **App (Frontend):** A web interface serving the UI.
2.  **Model Service (Backend):** A Python-based service hosting the machine learning model.
3.  **Lib-Version:** A shared Java library for version awareness used by the components.

## Repositories
- **Operation:** [doda25-team19/operation](https://github.com/doda25-team19/operation)
- **App:** [doda25-team19/app](https://github.com/doda25-team19/app)
- **Model Service:** [doda25-team19/model-service](https://github.com/doda25-team19/model-service)
- **Lib Version:** [doda25-team19/lib-version](https://github.com/doda25-team19/lib-version)

---

### Application Deployment (Helm Chart)

This repository contains a Helm chart `doda-app` that deploys the complete application stack (Frontend, Backend, Ingress).

#### 1. Installation

To install the application with default settings:

```bash
cd operation/helm/doda-app
helm install doda-app-release .
```

To uninstall:

```bash
helm uninstall doda-app-release
```

#### 2. Configuration & Hostnames

To support grading or custom environments, you can override default values in `values.yaml`.

**Changing the Hostname (Required for Grading):**
If you need to access the app via a different domain, override the hostname variable during installation:

```bash
helm install doda-app-release . --set hostname="my-grading-url.local"
```

**Resource Limits:**
CPU and Memory limits are configured by default but can be adjusted in `values.yaml` under `appService.resources` if the target environment has limited resources.

#### 3. Accessing the Application

The application is exposed via an Ingress Controller.

1. **Find the LoadBalancer IP:**

   ```bash
   kubectl get svc -n ingress-nginx
   ```

   Copy the `EXTERNAL-IP` (e.g., `192.168.56.90`).

2. **Update Local DNS:**
   Add the IP and hostname to your local `/etc/hosts` file (on your host machine, not the VM):

   ```
   # Replace <EXTERNAL-IP> with the IP from step 1
   <EXTERNAL-IP> doda-app.local
   ```

3. **Browse:**
   Open `http://doda-app.local` in your web browser.

#### Verification of Assignment Requirements

Run the following commands to verify that the *"Excellent"* grade criteria for Kubernetes Usage (A3) have been met.

**1. Verify ConfigMap & Secret Injection:**
Demonstrates that the app-service consumes configuration and sensitive data via environment variables.

```bash
# Get the pod name
APP_POD=$(kubectl get pod -l app=app-service -o jsonpath="{.items[0].metadata.name}")

# Check environment variables
kubectl describe pod $APP_POD | grep -A5 "Environment Variables"
```

Expected output: The output should reference `doda-app-release-configmap` and `doda-app-release-secret`.

**2. Verify HostPath Volume Mount:**
Demonstrates that the model-service mounts shared storage from the VirtualBox host (`/mnt/shared`).

```bash
# Get the pod name
MODEL_POD=$(kubectl get pod -l app=model-service -o jsonpath="{.items[0].metadata.name}")

# Check mounts
kubectl describe pod $MODEL_POD | grep -A5 "Mounts"
```

Expected output: The output should show `/data/shared` mounted from `shared-data-volume`.

#### Troubleshooting (macOS / Networking)

If you are testing on macOS or a restricted network environment and cannot reach `doda-app.local` via the browser — even after updating `/etc/hosts` — this is likely due to VirtualBox Host-Only network routing specific to the host machine.

**Fallback Verification Method:**
To verify that the application and Helm chart are working correctly without relying on the Ingress network bridge, use Kubernetes port-forwarding:

1. Run:

   ```bash
   kubectl port-forward svc/app-service 8080:80
   ```

   (Keep this terminal window open)

2. Open your browser to: `http://localhost:8080`

If the application loads successfully at `localhost:8080`, the Helm deployment is functioning correctly.

---
## Monitoring 

### Installation Steps

1. **Start Minikube**
```
minikube start
```

2. **Enable Ingress addon**
```
minikube addons enable ingress
```

3. **Wait for Ingress controller to be ready**
```
kubectl get pods -n ingress-nginx -w
```

4. **Update Helm dependencies**
```
   cd helm/doda-app
   helm dependency update
```

5. **Create an SMTP password secret**
```
kubectl create secret generic alertmanager-email-secret \
  --from-literal=password="password" \
  -n default

```

6. **Install the application** (first time)
```
   helm install doda-app . -f values.yaml
```
   
   **Or upgrade** (if already installed)
```
   helm upgrade doda-app . -f values.yaml
```

7. **Verify deployment**
```bash
   kubectl get pods
   kubectl get servicemonitor
   kubectl get ingress
   kubectl get prometheusrule
```

## Testing

### On macOS with Minikube
Due to Docker networking limitations, use minikube service:
```bash
minikube service -n ingress-nginx ingress-nginx-controller --url
```

### Use first URL (HTTP port) for testing:

```
curl -H "Host: doda-app.local" http://127.0.0.1:XXXXX
curl -H "Host: metrics.doda-app.local" http://127.0.0.1:XXXXX/metrics
```

If everything is correct, both curls should return an answer.

---

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
ansible-playbook -i inventory.cfg node.yaml```

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

The `admin.conf` file (your cluster credentials) is automatically copied to your `operation` directory. To use `kubectl` from your host machine, you can either use the `--kubeconfig` flag or export the environment variable.

**Option A (using a flag):**
```bash
kubectl --kubeconfig ./admin.conf get nodes
```

**Option B (more convenient):**
```bash
export KUBECONFIG=$(pwd)/admin.conf
# Now you can run kubectl commands directly
kubectl get nodes
kubectl get pods -A
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

To log in generate a token.
```bash
kubectl -n kubernetes-dashboard create token admin-user
```

## Assignment 1: Containerization
We have implemented subtasks F1, F2, F3, F6, F7, F8, F11.

### How to Run (Local Docker)
To run the application containerized locally without Kubernetes:
```bash
docker-compose up
```
