![image](../images/confluent-logo-300-2.png)

# Overview

This Confluent Operator demo showcases a variety of uses cases for deployment of Confluent Platform and supporting applications deployed via [Confluent Operator](https://docs.confluent.io/current/installation/operator/index.html).

# Prerequisites
The following is a set of general prerequisites, each individual use case may have additional requirements (check each use case documentation).

## Software Requirements
The following table indicates the applications required to be in the system PATH along with the versions verified in development of this demonstration.

| Dependency  | Verified Version  | Info  |
|---|---|---|
| `make`  | GNU 3.81  |   |
| `curl`  | 7.54  |   |
| `jq` | 1.6 | `jq` assists with parsing of JSON responses from various APIs used through the demo.<br>https://stedolan.github.io/jq/download/ |
| `kubectl` | Client v1.14.3  | https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-macos  |
| `helm` | Client 2.14.3 | https://helm.sh/docs/using_helm/#installing-the-helm-client |


## Compute Requirements
Depending on the specific use case demo, you will require access to a Kubernetes Cluster (1.9 or later). 

The demo provides tooling to create a cluster on popular Cloud Hosted Kubernetes Services.
| Service | Instructions | Info |
|---|---|---|
| [GKE](https://cloud.google.com/kubernetes-engine/) | <TOOD: Link to doc/scripting> | Google Kubernetes Engine |
| [EKS](https://aws.amazon.com/eks/) | <TODO: Link to doc/scripting> | AWS Elastic Kubernetes Service |
| [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) | <TODO: Link to doc/scripting> | Azure Kubernetes Service|

# Use Cases
| Demo | Info |
|---|---|
| [gke-base](gke-base/README.md) | A base deployment of Confluent Platform on Google Kubernetes Engine (GKE) with sample data generation using [Kafka Connect](https://docs.confluent.io/current/connect/index.html)|

# Documentation
See each individual use case above for detailed documentation on running the demos.

For further details on Confluent Operator, see the official [Operator Documentation](https://docs.confluent.io/current/installation/operator/co-deployment.html).

For more details on Kubernetes, see the official [Kubernetes Docs](https://kubernetes.io/docs/home/).