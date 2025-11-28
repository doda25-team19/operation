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
