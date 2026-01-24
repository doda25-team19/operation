# Extension Proposal: Automated Canary Analysis (ACA)

## 1. Identified Shortcoming: Manual Verification of Canary Releases

**Current State:**
In our current architecture (Assignment 4), we implemented a Canary Release strategy using Istio with a 90/10 traffic split. However, the decision process to promote a new version or trigger a rollback is entirely **manual**. 

**The Pain Point:**
Currently, a release engineer must manually deploy the new version, monitor Grafana dashboards for latency or error spikes, and manually update the `VirtualService` weights in the Helm chart to complete the release or revert it. This introduces:
* **Human Error:** Risk of misinterpreting metrics or reacting too slowly to a broken release.
* **Scalability Bottlenecks:** This process requires a human-in-the-loop for every microservice deployment.
* **Increased MTTR:** Manual detection and rollback lead to longer recovery times during failures.

## 2. Proposed Extension: Progressive Delivery with Flagger

**We propose** implementing **Automated Canary Analysis (ACA)** using [Flagger](https://flagger.app/), a Kubernetes operator that automates traffic shifting and analysis by interacting directly with Istio and Prometheus.

### 2.1 Concrete Technical Configuration
**We will** introduce a `Canary` Custom Resource to our Helm chart. This replaces our manual weight management in the `VirtualService` with an automated loop.

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: app-service
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-service
  service:
    port: 80
    targetPort: 8080
    gateways: [ {{ .Release.Name }}-gateway ]
    hosts: [ {{ .Values.hostname | quote }} ]
  analysis:
    interval: 1m      # Frequency of metric checks
    threshold: 5      # Max failed checks before automatic rollback
    maxWeight: 50     # Max canary traffic percentage
    stepWeight: 10    # Traffic increase per successful interval
    metrics:
      - name: "prediction-success-rate"
        templateRef:
          name: doda-success-rate
        thresholdRange:
          min: 99
        interval: 1m
      - name: "prediction-latency"
        templateRef:
          name: doda-p90-latency
        thresholdRange:
          max: 500
        interval: 1m
```

### 2.2 Automated Metrics & Decision Criteria
Flagger will automate the decision process by monitoring the following concrete PromQL queries derived from our existing application metrics:

1. **Success Rate:** `sum(irate(doda_predictions_total{app="app-service", version="new", result!="error"}[1m])) / sum(irate(doda_predictions_total{app="app-service", version="new"}[1m])) * 100`
2. **P90 Latency:** `histogram_quantile(0.90, sum(irate(doda_prediction_duration_seconds_bucket{app="app-service", version="new"}[1m])) by (le))`

**Advanced Reliability Check:** 
Since our existing Rate Limiting (EnvoyFilter) injects the header `x-local-rate-limit: true`, we will extend the analysis to monitor this header. If the canary triggers significantly more throttling than the stable version, Flagger will identify the performance regression and halt the rollout automatically.

## 3. Experiment Design: Measuring the Impact of ACA

To objectively evaluate this extension, **we will conduct** a fault-injection experiment to compare our current manual process against the proposed automated system.

**Hypothesis:** *Automating canary analysis with Flagger reduces the Mean Time to Detection (MTTD) of a faulty release and eliminates manual human intervention time.*

**Methodology:**
1. **Control Group (Current):** We deploy a faulty version of `app-service` (20% error rate). A team member monitors Grafana and manually updates the `VirtualService` to roll back traffic. We record the total time elapsed.
2. **Experimental Group (Proposed):** We deploy the same faulty version with Flagger enabled. Flagger detects the breach of the 99% success rate threshold via Prometheus and automatically reverts the Istio weights to 0% for the canary.
3. **KPI Comparison:** We expect the automated system to trigger a rollback within 2 minutes (the configured analysis interval), whereas the manual process typically requires 5-10 minutes of human observation and command-line execution.

## 4. References
1. **Flagger Documentation:** *Istio Canary Deployments.* [https://docs.flagger.app/tutorials/istio-progressive-delivery](https://docs.flagger.app/tutorials/istio-progressive-delivery)
2. **DODA Application Metrics:** Defined in `docs/continuous-experimentation.md`.
3. **Google SRE Book:** *Monitoring Distributed Systems* (Chapter 6) - On the importance of automated response for reducing operational toil.