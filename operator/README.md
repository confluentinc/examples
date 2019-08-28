![image](../images/confluent-logo-300-2.png)

# Overview

This Confluent Operator demo will work to show a variety of Operator use cases.  For further details see the official [Operator Documentation](https://docs.confluent.io/current/installation/operator/co-deployment.html).

# Prerequisites

The following is a set of general prerequisites, each individual use case may have additional requirements (check each use case README).  The following table indicates the applications required to be in the system PATH along with the versions verified in development of this demonstration.

| Dependency  | Verified Version  | Info  |
|---|---|---|
| `make`  | GNU 3.81  |   |
| `curl`  | 7.54  |   |
| `jq` | 1.6 | `jq` assists with parsing of JSON responses from various APIs used through the demo.<br>https://stedolan.github.io/jq/download/ |
| `kubectl` | Client v1.14.3  | https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-macos  |
| `helm` | Client 2.14.3 | https://helm.sh/docs/using_helm/#installing-the-helm-client |

# Use Cases
| Demo | Description |
|---|---|
| [gke-base](gke-base/README.md) | A base deployment of Confluent Platform on Google Kubernetes Engine (GKE) |

