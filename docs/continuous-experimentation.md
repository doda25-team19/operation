# Continuous experimentation for App Service v2

## Goal
Decide whether App Service v2 should replace v1 based on measurable performance and reliability.

## Change being tested
- **v1 stable** uses image value `appService.imageStable` and sets `APP_VERSION=old`
- **v2 canary** uses image value `appService.imageCanary` and sets `APP_VERSION=new`
- Both versions call the same model service backend through `MODEL_HOST`

## Traffic routing
- Main hostname `hostname` is routed with an Istio weighted split between **v1 stable** and **v2 canary**
- Pre release hostname `prereleaseHostname` routes 100 percent to **v2 canary** for testing and verification

## Hypothesis
Compared to **v1 stable**, **v2 canary** reduces prediction latency while keeping the error rate at the same level or lower.

## Metrics

### Primary metric
- **p90 prediction latency** measured by `doda_prediction_duration_seconds` using histogram quantile

### Guardrail metric
- **Error rate** measured from `doda_predictions_total` with `result="error"`, compared across versions

### Sanity metric
- **Request rate per version** measured from `doda_predictions_total` to confirm both versions receive traffic

## Grafana dashboard
Dashboard `doda a4 experiment` visualizes
- Prediction success and error rate split by version
- Latency quantiles `p50` and `p90` split by version
- Optional requests per version panel to confirm traffic split

## Screenshots
To be yet done, we need to add screenshots after running the experiment
- `docs/images/grafana_a4_rate.png`
- `docs/images/grafana_a4_latency.png`

## Decision criteria

### Accept v2 if all are true during the experiment window
- p90 latency for version `new` is at least 10-20 percent lower than version `old` for at least 15 minutes
- Error rate for version `new` is not more than 5-10 percent higher than version `old` for at least 15 minutes
- Both versions show non zero request rate in Grafana

### Reject v2 if any is true
- p90 latency for version `new` is higher than version `old` for at least 15 minutes
- Error rate for version `new` is more than 5-10 percent higher than version `old` for at least 5 minutes
- Metrics for version `new` are missing, which indicates scraping or labeling is broken

## How the dashboard supports the decision
The decision compares the p90 time series for `old` and `new` and checks the error rate series at the same time. If `new` is consistently lower on p90 without higher error rate, the change is accepted.