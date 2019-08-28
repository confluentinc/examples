
![image](../../images/confluent-logo-300-2.png)

# Overview

Demonstrates a deployment of Confluent Platform on Google Kubernetes Engine leveraging Confluent Operator.

# Prerequisites

> **Warning!** This example uses a real provider to launch _real_ resources.  To avoid unexpected charges, carefully evaluate the cost of resources before launching the demo and ensure all resources are destroyed after you are done evaluating the demonstration. 
In addition to the [common requirements](../README.md), the following table describes software or configuration required to execute this demonstration.

| Dependency  | Verified Version  | Info  |
|---|---|---|
| gcloud SDK| SDK:259.0.0<br>core:2019.08.16 | https://cloud.google.com/sdk/docs/downloads-interactive |
| `GCP` account w/ `GKE` permissions| n/a | A Google Cloud Platform account with proper configuration for the `gcloud` CLI and permissions to create and destroy a GKE cluster.<br>https://cloud.google.com/sdk/docs/initializing|
| `kubectl`|1.14.3|Configured with access to your GCP Project.<br>https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl|

# Usage

## Variables

The following values can be set on the command line or by exporting their values prior to executing the `make` command.

| Variable | Required | Default | Description |
|---|---|---|---|
| GCP_PROJECT_ID | Yes | n/a | Defines the Google Cloud Prlatform Project ID used by the demo |
| GKE_BASE_CLUSTER_ID | No | `cp-examples-operator` | The name of the Google Kubernetes Engine cluster that is created if the `gke-create-cluster` target is invoked. |
| GKE_BASE_ZONE | No | `us-central1-a` | The GCP Zone the GKE cluster will be created into |

Export the required GCP Project ID variable:
```
export GCP_PROJECT_ID=my-project-id
```

```
make demo
```
