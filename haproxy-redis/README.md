# HAProxy Setup for Redis + Sentinel deployments

[Redis](http://redis.io/) is an advanced key-value cache and store. It is often referred to as a data structure server since keys can contain strings, hashes, lists, sets, sorted sets, bitmaps and hyperloglogs.

[HAProxy](http://www.haproxy.org/) is a free, very fast and reliable solution offering high availability, load balancing, and proxying for TCP and HTTP-based applications. It is particularly suited for very high traffic web sites and powers quite a number of the world's most visited ones.

## TL;DR;

```bash
$ helm install haproxy-redis \
  --set redis.releaseName=... \
  --set redis.serviceName=... \
  --set redis.replicaCount=... \
  --set redis.namespace=...
```

By default this chart install 1 pod with:
 * an haproxy container which exposes 2 ports, one for a master redis instance and another for the slaves
 * a prometheus-exporter container which collects the metrics for the haproxy instance and exposes them to prometheus

## Introduction

This chart bootstraps a [HAProxy](http://www.haproxy.org/) server that interacts with a configured master/slave [Redis](http://redis.io/) cluster, exposing ports to access the master and the slaves in order to abstract clients of potentially new master elections; all this in a [Kubernetes](http://kubernetes.io) cluster using the Helm package manager.

## Prerequisites

- Kubernetes 1.5+ with Beta APIs enabled
- An existing Redis master/slave cluster installation running on a Kubernetes cluster

## Installing the Chart

To install the chart

```bash
$ helm install haproxy-redis \
  --set redis.releaseName=... \
  --set redis.serviceName=... \
  --set redis.replicaCount=... \
  --set redis.namespace=...
```

The command deploys HAProxy on the Kubernetes cluster interacting with the configured Redis cluster. By default this chart install one `haproxy` container and a `prometheus-exporter` sidecar container in charge of collect the metrics produced by the `haproxy` container. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the deployment:

```bash
$ helm delete <chart-name>
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the HAProxy-Redis chart and their default values.

| Parameter                        | Description                                                                                                                  | Default                                                   |
| -------------------------------- | -----------------------------------------------------                                                                        | --------------------------------------------------------- |
| `namespace`                      | Namespace for the chart      | `default`    |
| `serviceAccount.create`                          | Creates a service account for the deployment |  `true`|
| `serviceAccount.name`                          | Name for the Service Account (generates one if empty) |  `""` |
| `haproxy.nodeSelector`                          | Node labels for pod assignment | `{}` |
| `haproxy.image`                          | HAProxy image with tag | `haproxy:1.8-alpine` |
| `haproxy.resources`                | CPU/Memory pod nodes resource requests/limits        | Memory: `200Mi`, CPU: `100m`|
| `haproxy.replicas`                | Number of instances to be created        | `1` |
| `haproxy.ports`                | The HAProxy ports that will be binded for the Redis master and slaves         | `master: 6379`, `slave:6380`|
| `haproxy.bindAddresses`                | Allowed addresses (defaults to all)        | `*`|
| `haproxy.stats.http`                | Exposes the HAProxy stats page       | `enable: false`, `port: 9094`|
| `haproxy.stats.socket`                | Exposes HAProxy stats using local sockets         | `enable: true`|
| `services.type`                | Type of the service to be created        | `LoadBalancer`|
| `services.annotations`                | Annotations for the service        | `{"cloud.google.com/load-balancer-type":"Internal"}`|
| `services.masterIP`                | IP for the master service (will generate one if not provided)       | `""`|
| `services.slaveIP`                | IP for the slave service (will generate one if not provided)       | `""`|
| `redis.port`                | Port of the service to be exposed       | `6379`|
| `redis.releaseName`                | Name of the `redis-ha` chart release (**mandatory**)      | ``|
| `redis.namespace`                | Namespace of the `redis-ha` chart release (**mandatory**)        | ``|
| `redis.serviceName`                | Service name of the `redis-ha` chart release (**mandatory**)        | ``|
| `redis.replicaCount`                | Number of replicas for the `redis-ha` chart release (**mandatory**)        | ``|
| `redis.maxConnections`                | Port of the service to be exposed       | `9900`|
| `redis.checkSeconds`                | HAProxy backend check time in seconds       | `1`|

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
$ helm install haproxy-redis \
  --set redis.releaseName=test \
  --set redis.serviceName=test \
  --set redis.replicaCount=3 \
  --set redis.namespace=default
```

The above command sets the HAProxy server within `default` namespace.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install -f values.yaml haproxy-redis
```

> **Tip**: You can use the default [values.yaml](values.yaml)
