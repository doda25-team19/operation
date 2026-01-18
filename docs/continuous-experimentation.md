# Continuous experimentation

## Goal
Decide whether App Service v2 should replace v1 based on measurable performance and reliability.

## Change being tested
- **v1 stable** uses image value `appService.imageStable` and sets `APP_VERSION=v1-stable`
- **v2 canary** uses image value `appService.imageCanary` and sets `APP_VERSION=v2-canary`
- Both versions call the same model service backend through `MODEL_HOST`

In Prometheus and Grafana, the comparison is done using the label `version`.
This label is copied into the scraped metric series from the Pod label `version` by the ServiceMonitor setting `podTargetLabels`.

## Experiment setup
### Traffic split
- Main hostname `hostname` is routed with an Istio weighted split between **v1 stable** and **v2 canary**
- Pre release hostname `prereleaseHostname` routes 100 percent to **v2 canary** for testing and verification

## Hypothesis
Compared to **v1 stable**, **v2 canary** reduces prediction latency while keeping the error rate at the same level or lower.

## Metrics used
### Primary metrics
1. **Prediction latency p90**
   - Metric source `doda_prediction_duration_seconds_bucket`
   - Grafana panel uses `histogram_quantile(0.9, ...)` grouped by `version`

2. **Error rate**
   - Metric source `doda_predictions_total{result="error"}`
   - Grafana panel compares error ratio per version

### Secondary metrics
1. **Requests per second**
   - Metric source `doda_predictions_total`
   - Used to confirm both versions receive traffic

2. **Input text length**
   - Metric source `doda_input_text_length`
   - Used for sanity checking input characteristics during tests

## Decision criteria
### Experiment window
- Run the experiment for at least 15 minutes after both versions are confirmed as scraped by Prometheus
- Ensure both versions show data in Grafana

### Accept v2 if all are true during the experiment window
- p90 latency for version `v2-canary` is at least 10-20 percent lower than version `v1-stable` for at least 15 minutes
- Error rate for version `v2-canary` is not more than 5-10 percent higher than version `v1-stable` for at least 15 minutes

### Reject v2 if any is true
- p90 latency for version `v2-canary` is higher than version `v1-stable` for at least 15 minutes
- Error rate for version `v2-canary` is more than 5-10 percent higher than version `v1-stable` for at least 5 minutes
- Metrics for version `v2-canary` are missing, which indicates scraping or labeling is broken

## Dashboard screenshots
Add screenshots in `docs/images` and reference them here.
- `docs/images/grafana_a4_rate.png`
- `docs/images/grafana_a4_latency.png`

## How the dashboard supports the decision
The dashboard shows request volume by result and version, plus latency quantiles by version.
If `v2-canary` stays lower on p90 without higher error rate, the change is accepted.
