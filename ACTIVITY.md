### Week Q2.1
Meet with the group at the lab. 

### Week Q2.2
- Jeroen: https://github.com/doda25-team19/lib-version/pull/2
This week I worked on A1/F2 Library Release. A workflow is used to automatically package and version lib-version and to release it in the GitHub package registry for Maven.

 - Miroslav: https://github.com/doda25-team19/operation/pull/1
For this week I worked on A1/F7 - docker compose. I built and pushed the images for the 2 containers, created the .yml compose file and .env file for the variables.

- Arda: https://github.com/doda25-team19/lib-version/pull/1
This week I worked on A1/F1 Version-aware Library. I implemented the VersionUtil class and configured Maven resource filtering to inject the version directly from the pom.xml metadata.

- Benas: https://github.com/doda25-team19/app/pull/3 https://github.com/doda25-team19/model-service/pull/1
This week I worked on A1/F6 Flexible Containers. I made it possible to define the port on which the app and the model-service run through an ENV variable.

- Mikolaj: https://github.com/doda25-team19/app/pull/5 https://github.com/doda25-team19/model-service/pull/2
This week I worked on A1/F8 – Automated container image releases. I implemented the GitHub Actions workflows for both the app and model-service repositories, enabling automated Docker image builds and publishing to GHCR on version tags.

- Viktor: https://github.com/doda25-team19/app/pull/2
This week, Viktor worked on A1/F3. He created Dockerfiles for the app and model-service that allows to build two container images.

### Week Q2.3
- Arda: https://github.com/doda25-team19/lib-version/pull/3 https://github.com/doda25-team19/operation/pull/6
This week I worked on A1/F11 and A2/Steps 13-17. I implemented advanced versioning workflows for lib-version and automated the Kubernetes Controller provisioning (including Flannel, Helm, and dynamic inventory generation) for the cluster setup.

- Benas: https://github.com/doda25-team19/operation/pull/3
This week I implemented Steps 3-8 of A2. I created and tested the Ansible playbooks, added SSH key registration, disabled swap, loaded required kernel modules, enabled sysctl settings, and generated dynamic /etc/hosts files for all VMs.

- Miroslav: https://github.com/doda25-team19/operation/pull/5
This week I worked on steps 9-12 of A2, preped the VMs for kubernetes by installing the required tools at the right versions.

- Mikolaj: https://github.com/doda25-team19/operation/pull/7
This week I worked on A2/Steps 18–20, implementing the Ansible automation for joining worker nodes to the Kubernetes cluster and adding the finalization playbook that installs and configures MetalLB. I also started working on A1/F10.

- Jeroen: 
    - https://github.com/doda25-team19/operation/pull/2 -
    This week I worked on A2. I completed Step 1 and 2. created vm with vagrant. Dual configuration for ARM and INTEL architecture. Added network configuration to access the vm from host machine.
    - https://github.com/doda25-team19/app/pull/6 -
    This week I worked on A1/F5Add explicit clean up of apt cache in dockerfiles to reduce image size. The multistage build was already implemented.
- Viktor: https://github.com/doda25-team19/operation/pull/10
   This week was a bit lighter in terms of development for A1, as in luck of the draw, I did not have to implement anything from a1, as there were only 5 parts, so I took the initiative to look at all a1 PRs.
   Additionally, I took care of steps 21-23 for A2, which set up the Nginx Ingress Controller, the Kubernetes Dashboard, and enabling Istio support

### Week Q2.4
- Arda: https://github.com/doda25-team19/operation/pull/11 This week I created a Helm chart for deploying our application to Kubernetes, implementing a ConfigMap, Secret, and hostPath Volume.

- Benas: https://github.com/doda25-team19/operation/pull/14
This week I implemented my dedicated parts for A3. I implemented alerting for the application by configuring Alertmanager in the Prometheus stack. I also added PrometheusRule alerts based on application metrics, and secured SMTP credentials using a Kubernetes Secret.

- Miroslav: https://github.com/doda25-team19/operation/pull/13
I worked on integrating Prometheus into our Helm chart by adding the prometheus stack as a dependency. Also created a service monitor to scrape the /metrics endpoints.

- Mikolaj: https://github.com/doda25-team19/operation/pull/16
This week I worked on A3 dashboard automation. I implemented automatic Grafana dashboard provisioning using a ConfigMap and the Grafana sidecar, integrated dashboard loading into the Helm chart, and updated the chart configuration to merge Prometheus, Alertmanager, and Grafana settings.

- Jeroen: https://github.com/doda25-team19/app/pull/8
This week I worked on A3. I implemented the application instrumentation. It exposes a /metrics endpoint that serves application metrics in the Prometheus text exposition format. 


    
- Viktor: https://github.com/doda25-team19/operation/pull/15 This week I added Grafana to the Helm chart, configured it with the Prometheus datasource and created two ready to import dashboards stored as JSON files in the operations repo.
  
### Week Q2.5
- Jeroen: https://github.com/doda25-team19/operation/pull/18
Implemented Istio rate limiting (5 req/min per connection) for model-service using EnvoyFilter and added sidecar injection to all deployments.

- Mikolaj: https://github.com/doda25-team19/operation/pull/17
This week I implemented the Gateway and VirtualService resources in the Helm chart to route traffic to the app-service and updated values.yaml to make the ingress gateway name fully configurable.

- Viktor: https://github.com/doda25-team19/app/pull/10 https://github.com/doda25-team19/operation/pull/21
  Worked on implementing the different versions experiment to compare the stable and canary versions of the app service

- Benas: https://github.com/doda25-team19/operation/pull/19
This week, I implemented my dedicated parts for A4. I added 2 deployment versions for app-service and model-service, DestinationRule with subsets, and virtualservice with 90/10 routing.

- Arda: https://github.com/doda25-team19/operation/pull/22
Researched Automated Canary Analysis (ACA) and Flagger to address manual verification shortcomings. Drafted the Extension Proposal docs/extension.md to fulfill the Release Engineering extension requirement.

- Miroslav: https://github.com/doda25-team19/operation/pull/20
This week I was given the task to introduce sticky sessions, the PR is draft since I don't have it yet. (wrapped up in week 6)

### Week Q2.6
- Arda: https://github.com/doda25-team19/operation/pull/23
Finalized the project documentation. Created docs/deployment.md with Mermaid diagrams visualizing the Istio Traffic Flow and the 90/10 Canary split strategy.

- Mikolaj: https://github.com/doda25-team19/model-service/pull/4 https://github.com/doda25-team19/operation/pull/24
Finalized A1/F10 - No hard-coded model. Implemented environment variable logic for model loading in the backend and updated the Helm chart to inject this configuration into the deployments.

- Viktor: https://github.com/doda25-team19/operation/pull/25
Worked on the experiment docs for A4, had to fix the values.yaml to use correct images for both versions and include the prerelease hosting. Also created a new virtual-service-prerelease.yaml

### Week Q2.7
- Arda: https://github.com/doda25-team19/operation/pull/26
Added the Extension Proposal (A4) regarding Automated Canary Analysis with Flagger. Refactored the Helm Chart (A3) to externalize the Model Service URL in `values.yaml` for better configurability.

- Mikolaj: https://github.com/doda25-team19/operation/pull/27
Added Kubernetes resource requests and limits for the model-service deployments, which prevents resource contention in the cluster, improving overall application stability.

- Miroslav: https://github.com/doda25-team19/model-service/pull/5
Tested the model release workflow since I didn't manage to do it previously. It turned out to be fine, so no changes on that. Added documentation for the model training and releasing as well as how to test the model.

