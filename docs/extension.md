# Extension Proposal: Automated Canary Analysis (ACA)

## 1. Identified Shortcoming: Manual Verification of Canary Releases

**Current State:**
In the current architecture (Assignment 4), we implemented a Canary Release strategy using Istio. We split traffic 90/10 between stable and canary versions. However, the decision process to promote the canary (increase traffic) or rollback (if errors occur) is entirely **manual**.

**The Pain Point:**
A release engineer must:
1.  Deploy the new version.
2.  Manually edit `VirtualService` weights.
3.  Stare at Grafana dashboards for latency or error spikes.
4.  Manually revert configuration if issues arise.

**Risks:**
*   **Human Error:** Misinterpreting a metric spike or reacting too slowly to errors.
*   **Scalability:** This process cannot scale to hundreds of microservices; it requires a human in the loop for every deployment.
*   **Downtime:** If the canary is broken, users suffer until a human notices and manually rolls back.

## 2. Proposed Extension: Progressive Delivery with Flagger

To address this, I propose implementing **Automated Canary Analysis (ACA)** using [Flagger](https://flagger.app/), a Kubernetes operator that automates the promotion of canary deployments using Istio.

### Architecture Changes
Instead of manually defining `VirtualService` weights in our Helm chart, we will delegate traffic management to the Flagger operator.

1.  **Install Flagger Controller:** Run Flagger in the cluster alongside Istio.
2.  **Define `Canary` CRD:** Introduce a Custom Resource Definition that defines:
    *   **Target:** The deployment to track (e.g., `app-service`).
    *   **Analysis Interval:** How often to check metrics (e.g., every 1 minute).
    *   **Thresholds:** Max request duration (e.g., 500ms) and success rate (e.g., 99%).
    *   **Step Weight:** How much to increase traffic per step (e.g., 5% -> 10% -> 50%).

### Visualizing the Improvement

**Before (Current):**
`Developer -> Helm Install -> [Manual Wait/Check Grafana] -> [Manual Update Weight] -> Release`

**After (Proposed):**
`Developer -> Helm Install -> Flagger detects change -> [Loop: Adjust Istio Traffic -> Query Prometheus -> Check Thresholds -> Continue/Rollback] -> Release`

### Implementation Plan (1-3 Days Effort)

1.  **Provisioning:** Update Ansible `ctrl.yaml` to install the Flagger Helm chart.
2.  **Metrics:** Ensure our existing Prometheus setup exposes the Istio metrics (`istio_requests_total`, `istio_request_duration_seconds`) which Flagger queries by default.
3.  **Refactoring:**
    *   Remove explicit `VirtualService` and `DestinationRule` definitions from our `doda-app` Helm chart.
    *   Add a `canary.yaml` template to the Helm chart.
4.  **Testing:** Deliberately deploy a broken version (returning 500 errors) and verify that Flagger automatically halts traffic to the canary and rolls back without human intervention.

## 3. Assumptions and Downsides

*   **Complexity:** Introducing another operator adds complexity to the cluster. If Flagger fails, deployments might get stuck.
*   **Metric Reliance:** The automation is only as good as the metrics. If the app fails silently (returning HTTP 200 but empty bodies), Flagger will wrongly promote the release. We must implement deep health checks.

## 4. References

1.  **Flagger Documentation:** *Istio Canary Deployments.* Available at: [https://docs.flagger.app/tutorials/istio-progressive-delivery](https://docs.flagger.app/tutorials/istio-progressive-delivery)
2.  **Martin Fowler:** *CanaryRelease.* Available at: [https://martinfowler.com/bliki/CanaryRelease.html](https://martinfowler.com/bliki/CanaryRelease.html) - Discusses the conceptual foundation of reducing risk.
3.  **Google SRE Book:** *Service Level Objectives.* Explains why error budgets and automated monitoring are critical for reliability.