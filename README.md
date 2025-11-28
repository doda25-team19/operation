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

#### Step 21: Deploy the Application

1.  Apply the Kubernetes manifests for the model service. These are located in the `k8s` folder.
    ```bash
    # Run these commands from your host machine
    kubectl apply -f k8s/model-service-deployment.yaml
    kubectl apply -f k8s/model-service-ingress.yaml
    ```
2.  Verify the deployment:
    ```bash
    kubectl get deploy,svc,ingress
    ```
    The `model-service` should now be available inside the cluster at `app.local`.

#### Step 22: Install Kubernetes Dashboard

1.  Install the dashboard using Helm and our custom values:
    ```bash
    helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
    helm repo update
    helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
      --namespace kubernetes-dashboard \
      --create-namespace \
      -f k8s/k8s-dashboard-values.yaml
    ```
2.  Create the admin user and expose the dashboard via Ingress:
    ```bash
    kubectl apply -f k8s/dashboard-admin-user.yaml
    kubectl apply -f k8s/dashboard-ingress.yaml
    ```
3.  Add the following entry to your host machine's `hosts` file (`/etc/hosts` on macOS/Linux):
    ```
    192.168.56.90    dashboard.local
    ```
4.  Access the dashboard at `https://dashboard.local` and use the token from this command to log in:
    ```bash
    kubectl -n kubernetes-dashboard create token admin-user
    ```

#### Step 23: Install Istio

1.  Download and install Istio using the `demo` profile:
    ```bash
    curl -L https://istio.io/downloadIstio | sh -
    cd istio-*
    ./bin/istioctl install --set profile=demo -y
    ```
2.  Verify the installation. You should see pods and services for Istio running:
    ```bash
    kubectl get pods -n istio-system
    kubectl get svc -n istio-system
    ```

---

## Assignment 1: Containerization
We have implemented subtasks F1, F2, F3, F6, F7, F8, F11.

### How to Run (Local Docker)
To run the application containerized locally without Kubernetes:
```bash
docker-compose up
```
