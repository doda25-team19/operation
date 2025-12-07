# DODA Project - Team 19

## Architecture
Microservices application with:
- **App (Frontend):** Web UI
- **Model Service (Backend):** Python ML prediction service
- **Lib-Version:** Shared Java library for version awareness

## Repositories
- [Operation](https://github.com/doda25-team19/operation) | [App](https://github.com/doda25-team19/app) | [Model Service](https://github.com/doda25-team19/model-service) | [Lib Version](https://github.com/doda25-team19/lib-version)

---

## Application Deployment (Helm Chart)

### Installation

```bash
cd operation/helm/doda-app
helm install doda-app-release .              # Install
helm upgrade doda-app-release . -f values.yaml  # Upgrade
helm uninstall doda-app-release              # Uninstall
```

**Custom hostname for grading:**
```bash
helm install doda-app-release . --set hostname="my-grading-url.local"
```

### Accessing the Application

1. Get LoadBalancer IP: `kubectl get svc -n ingress-nginx`
2. Add to `/etc/hosts`: `<EXTERNAL-IP> doda-app.local`
3. Browse: http://doda-app.local

**Fallback (port-forward):** `kubectl port-forward svc/app-service 8080:80` then access http://localhost:8080

### Verification (Assignment A3)

**ConfigMap & Secret Injection:**
```bash
APP_POD=$(kubectl get pod -l app=app-service -o jsonpath="{.items[0].metadata.name}")
kubectl describe pod $APP_POD | grep -A5 "Environment Variables"
# Should show doda-app-release-configmap and doda-app-release-secret
```

**HostPath Volume Mount:**
```bash
MODEL_POD=$(kubectl get pod -l app=model-service -o jsonpath="{.items[0].metadata.name}")
kubectl describe pod $MODEL_POD | grep -A5 "Mounts"
# Should show /data/shared mounted from shared-data-volume
```
---
## Monitoring

### Setup (Minikube)
```bash
minikube start
minikube addons enable ingress
kubectl get pods -n ingress-nginx -w  # Wait for ready

cd helm/doda-app
helm dependency update

# Create alertmanager secret
kubectl create secret generic alertmanager-email-secret \
  --from-literal=password="password" -n default

# Install or upgrade
helm install doda-app . -f values.yaml    # First time
helm upgrade doda-app . -f values.yaml    # Update

# Verify
kubectl get pods,servicemonitor,ingress,prometheusrule
```

### Testing (macOS/Minikube)
```bash
# Get minikube URL
minikube service -n ingress-nginx ingress-nginx-controller --url

# Test with first URL (HTTP port)
curl -H "Host: doda-app.local" http://127.0.0.1:XXXXX
curl -H "Host: metrics.doda-app.local" http://127.0.0.1:XXXXX/metrics
```

---

## Istio Rate Limiting

Per-IP rate limiting (5 req/min) on model-service using Istio EnvoyFilter with token bucket algorithm. Returns HTTP 429 when limit exceeded.

### Verification

```bash
kubectl get pods  # Should show 2/2 containers (app + istio-proxy)
kubectl get virtualservice,destinationrule,envoyfilter
```

### Testing Rate Limiting

**Test 1: Basic Rate Limiting**

Send 7 requests quickly to observe rate limiting in action:
```bash
for i in {1..7}; do
  curl -X POST http://doda-app.local/predict \
    -H "Content-Type: application/json" \
    -d '{"sms":"test message"}' \
    -w "\nStatus: %{http_code}\n"
  sleep 1
done
```

**Expected Result:**
- Requests 1-5: HTTP 200 (success)
- Requests 6-7: HTTP 429 (rate limited)

**Test 2: Token Bucket Refill**

Verify that rate limits reset after the fill interval:
```bash
# Hit the rate limit
for i in {1..6}; do
  curl -X POST http://doda-app.local/predict \
    -H "Content-Type: application/json" \
    -d '{"sms":"test"}' -s -o /dev/null
done

# Wait for token bucket to refill
echo "Waiting 60 seconds for token refill..."
sleep 60

# Try again - should succeed
curl -X POST http://doda-app.local/predict \
  -H "Content-Type: application/json" \
  -d '{"sms":"test message"}' \
  -w "\nStatus: %{http_code}\n"
```

**Expected Result:** After 60 seconds, the request succeeds (HTTP 200)

**Test 3: Per-IP Isolation**

Different client IPs have independent quotas. If you have access to multiple machines or can use different source IPs, verify that rate limiting is isolated per IP.

### Viewing Envoy Metrics

Check Istio's rate limiting metrics from the Envoy proxy:
```bash
# Get the model-service pod name
MODEL_POD=$(kubectl get pod -l app=model-service -o jsonpath="{.items[0].metadata.name}")

# View rate limiting metrics
kubectl exec -it $MODEL_POD -c istio-proxy -- \
  curl localhost:15000/stats/prometheus | grep local_rate_limit
```

Look for metrics like:
- `envoy_local_rate_limit_enabled`
- `envoy_local_rate_limit_enforced`
- `envoy_http_local_rate_limit_rate_limited`

### Configuration

Rate limiting settings are configurable in `values.yaml`:

```yaml
istio:
  enabled: true  # Enable/disable Istio features
  sidecarInjection:
    enabled: true  # Enable sidecar injection
  rateLimiting:
    enabled: true  # Enable rate limiting
    requestsPerMinute: 5  # Not used directly (kept for clarity)
    burstSize: 5  # Maximum tokens in bucket
    fillInterval: 60  # Token refill interval in seconds
```

**To adjust rate limits:**

1. Edit `helm/doda-app/values.yaml`
2. Modify `istio.rateLimiting.burstSize` (max requests) or `fillInterval` (refill period)
3. Upgrade the Helm release:
   ```bash
   cd helm/doda-app
   helm upgrade doda-app . -f values.yaml
   ```
4. Wait for pods to restart with updated configuration

**Example:** To allow 10 requests per 2 minutes:
```yaml
istio:
  rateLimiting:
    burstSize: 10
    fillInterval: 120
```

### Disabling Rate Limiting

To disable rate limiting without removing Istio:
```yaml
istio:
  rateLimiting:
    enabled: false
```

To disable all Istio features:
```yaml
istio:
  enabled: false
  sidecarInjection:
    enabled: false
  rateLimiting:
    enabled: false
```

Then upgrade the Helm release.

### Troubleshooting

**Issue:** Pods show 1/1 containers instead of 2/2
- **Cause:** Istio sidecar injection is not working
- **Solution:** Ensure Istio is installed: `kubectl get pods -n istio-system`
- **Solution:** Check deployment annotations: `kubectl get deployment model-service -o yaml | grep sidecar.istio.io/inject`

**Issue:** Rate limiting not working (all requests succeed)
- **Cause:** EnvoyFilter not applied
- **Solution:** Check if EnvoyFilter exists: `kubectl get envoyfilter`
- **Solution:** Check Envoy configuration: `kubectl exec -it $MODEL_POD -c istio-proxy -- curl localhost:15000/config_dump | grep local_rate_limit`

**Issue:** All requests return HTTP 429 immediately
- **Cause:** Rate limit configuration too restrictive or misconfigured
- **Solution:** Check values.yaml settings and ensure `burstSize` and `fillInterval` are reasonable

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
