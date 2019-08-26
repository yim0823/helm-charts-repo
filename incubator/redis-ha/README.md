# Redis-Ha

본 차트는 [stable/redis-ha](https://github.com/helm/charts/tree/master/stable/redis-ha) 를 customizing 한 것으로 
[Redis](http://redis.io/) 를 Kubernetes 환경에서 `Active-Standby 구조`를 구성한다.
Kube-Proxy 를 통해 requests 를 Master 로 routing 하기 위한 구성이고 sentinel 이 master 의 상태를 감시한다.
즉, redis master-slave 는 standalone 으로 구성되며 slave 는 master 와 계속 data 에 대해 sync 를 하며 master 와 동일한 data 를 유지한다.  

## Introduction

- 모든 requests 는 master 에서 처리하고 slave 는 master 의 데이터를 동일하게 갖게하며, master 장애 상태일 때, slave 를 master 로 promoted 하여 failover 를 한다. 장애가 조취된 old master 는 slave 로 demoted 된다.  
- Kubernetes 환경에서,
  - kube-proxy 를 활용해 requests 를 write request 는 master 로, read request 는 slaves 로 routing 하는 것이 목적이다.
  - kube-proxy 로 HAProxy 를 대체하고자 한다.
    - Kubernetes 환경이 아닌 환경에서 Redis High Availability 를 가져가기 위해 HAProxy 를 중간에 두고 forwarding 를 하는 구조를 많이 사용한다.

## Difference from stable/redis-ha

- stable/redis-ha 는 각 pod 마다 service (redis-ha-announce-server-*) 가 붙고 Headless service 로 묶이는 구성이되는 반면, 
  - 본 차트는 headless 로 pods 을 proxy 한다.
- stable/redis-ha 는 redis container 에 대해 livenessProbe 만 존재하고 이 livenessProbe 는 redis-cli ping 명령으로 live 를 확인하는 script 를 실행해 체크하는 로직으로 되어 있는 반면,
  - 본 차트는 livenessProbe 뿐만 아니라 redis-cli role 명령으로 해당 노드의 redis 상의 역할을 체크해 master 를 찾는 script 를 실행하는 readinessProbe 를 추가했다.
  - 이 readinessProbe 의 목적은 master 를 찾아, kube-proxy 입장에서는 master 만 서비스 준비가 된 것으로 판단해 master 로만 request 를 forwarding 하는 것이다.
- stable/redis-ha 는 master 1대, slave n대로 구성하는 반면,
  - 본 차트는 active-standby 구조로 `master:slave=1:1` 구성으로 `quorum 1`개로 가져간다.

## Prerequisites

- Kubernetes 1.8+ with Beta APIs enabled
- PV provisioner support in the underlying infrastructure

## Adding the private chart repo

```bash
$ helm repo add yim0823-incubator https://raw.githubusercontent.com/yim0823/helm-charts-repo/master/incubator/
$ helm repo list
$ helm repo update
```
## Installing the Chart

```bash
$ helm install yim0823-incubator/redis-ha -f redis-values-sample.yaml --name mec --namespace redis-ha
```
> * -f option, value.yaml 파일과 경로 지정
> * --name option, kubernetes 상에서 해당 chart 로 생성되는 resource 들의 공통 이름
> * --namespace option, kubernetes 상에서 namespace 지정

## Uninstalling the Chart

To uninstall/delete the deployment:

```bash
$ helm delete yim0823-incubator/redis-ha
```

이 차트로 release 된 kubernetes 상에 관련된 모든 components 를 삭제한다.

> **Tip** kubernetes 상에 `mec` 으로 naming 된 모든 components 를 삭제한다.
> ```bash
> $ helm delete --purge mec
> ```

## Configuration

The following table lists the configurable parameters of the Redis chart and their default values.

| Parameter                | Description                                                                                                                                                                                              | Default                                                                                    |
|:-------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------|
| `image`                  | Redis image                                                                                                                                                                                              | `redis`                                                                                    |
| `tag`                    | Redis tag                                                                                                                                                                                                | `5.0.5-alpine`                                                                             |
| `replicas`               | Number of redis master/slave pods                                                                                                                                                                        | `3`                                                                                        |
| `serviceAccount.create`  | Specifies whether a ServiceAccount should be created                                                                                                                                                     | `true`                                                                                     |
| `serviceAccount.name`    | The name of the ServiceAccount to create                                                                                                                                                                 | Generated using the redis-ha.fullname template                                             |
| `rbac.create`            | Create and use RBAC resources                                                                                                                                                                            | `true`                                                                                     |
| `redis.port`             | Port to access the redis service                                                                                                                                                                         | `6379`                                                                                     |
| `redis.masterGroupName`  | Redis convention for naming the cluster group                                                                                                                                                            | `mymaster`                                                                                 |
| `redis.config`           | Any valid redis config options in this section will be applied to each server (see below)                                                                                                                | see values.yaml                                                                            |
| `redis.customConfig`     | Allows for custom redis.conf files to be applied. If this is used then `redis.config` is ignored                                                                                                         | ``                                                                                         |
| `redis.resources`        | CPU/Memory for master/slave nodes resource requests/limits                                                                                                                                               | `{}`                                                                                       |
| `sentinel.port`          | Port to access the sentinel service                                                                                                                                                                      | `26379`                                                                                    |
| `sentinel.quorum`        | Minimum number of servers necessary to maintain quorum                                                                                                                                                   | `2`                                                                                        |
| `sentinel.config`        | Valid sentinel config options in this section will be applied as config options to each sentinel (see below)                                                                                             | see values.yaml                                                                            |
| `sentinel.customConfig`  | Allows for custom sentinel.conf files to be applied. If this is used then `sentinel.config` is ignored                                                                                                   | ``                                                                                         |
| `sentinel.resources`     | CPU/Memory for sentinel node resource requests/limits                                                                                                                                                    | `{}`                                                                                       |
| `init.resources`         | CPU/Memory for init Container node resource requests/limits                                                                                                                                              | `{}`                                                                                       |
| `auth`                   | Enables or disables redis AUTH (Requires `redisPassword` to be set)                                                                                                                                      | `false`                                                                                    |
| `redisPassword`          | A password that configures a `requirepass` and `masterauth` in the conf parameters (Requires `auth: enabled`)                                                                                            | ``                                                                                         |
| `authKey`                | The key holding the redis password in an existing secret.                                                                                                                                                | `auth`                                                                                     |
| `existingSecret`         | An existing secret containing a key defined by `authKey` that configures `requirepass` and `masterauth` in the conf parameters (Requires `auth: enabled`, cannot be used in conjunction with `.Values.redisPassword`) | ``                                                                                         |
| `nodeSelector`           | Node labels for pod assignment                                                                                                                                                                           | `{}`                                                                                       |
| `tolerations`            | Toleration labels for pod assignment                                                                                                                                                                     | `[]`                                                                                       |
| `hardAntiAffinity`      | Whether the Redis server pods should be forced to run on separate nodes.                                                                                                                                  | `true`                                                                                     |
| `additionalAffinities`  | Additional affinities to add to the Redis server pods.                                                                                                                                                    | `{}`                                                                                       |
| `affinity`               | Override all other affinity settings with a string.                                                                                                                                                      | `""`                                                                                       |
| `exporter.enabled`       | If `true`, the prometheus exporter sidecar is enabled                                                                                                                                                    | `false`                                                                                    |
| `exporter.image`         | Exporter image                                                                                                                                                                                           | `oliver006/redis_exporter`                                                                 |
| `exporter.tag`           | Exporter tag                                                                                                                                                                                             | `v0.31.0`                                                                                  |
| `exporter.annotations`   | Prometheus scrape annotations                                                                                                                                                                            | `{prometheus.io/path: /metrics, prometheus.io/port: "9121", prometheus.io/scrape: "true"}` |
| `exporter.extraArgs`     | Additional args for the exporter                                                                                                                                                                         | `{}`                                                                                       |
| `podDisruptionBudget`    | Pod Disruption Budget rules                                                                                                                                                                              | `{}`                                                                                       |
| `hostPath.path`          | Use this path on the host for data storage                                                                                                                                                               | not set                                                                                    |
| `hostPath.chown`         | Run an init-container as root to set ownership on the hostPath                                                                                                                                           | `true`                                                                                       |
| `sysctlImage.enabled`                      | Enable an init container to modify Kernel settings                                                             | `false`                                              |
| `sysctlImage.command`                      | sysctlImage command to execute                                                                                 | []                                                   |
| `sysctlImage.registry`                     | sysctlImage Init container registry                                                                            | `docker.io`                                          |
| `sysctlImage.repository`                   | sysctlImage Init container name                                                                                | `bitnami/minideb`                                    |
| `sysctlImage.tag`                          | sysctlImage Init container tag                                                                                 | `latest`                                             |
| `sysctlImage.pullPolicy`                   | sysctlImage Init container pull policy                                                                         | `Always`                                             |
| `sysctlImage.mountHostSys`                 | Mount the host `/sys` folder to `/host-sys`                                                                    | `false`                                              |
| `schedulerName`                            | Alternate scheduler name                                                                                       | `nil`                                                |

## Configure the redis-ha (active-standby)

### 1. Installing the chart

![redis-ha_2 install-helm-chart](https://user-images.githubusercontent.com/3222837/63569080-c7e47700-c5b2-11e9-87fc-838fd5fcd5da.png)

![redis-ha_3 check-headless](https://user-images.githubusercontent.com/3222837/63569089-d599fc80-c5b2-11e9-9ca9-f36ff67929b6.png)

### 2. Check pods and service

![redis-ha_4 check-pods-and-services](https://user-images.githubusercontent.com/3222837/63569134-067a3180-c5b3-11e9-9fd9-a8c44969f79b.png)

### 3. Check the role of redis on each node

![redis-ha_5-1 check-role-of-redis](https://user-images.githubusercontent.com/3222837/63569163-2c073b00-c5b3-11e9-99a7-ffce1db48e16.png)

![redis-ha_5-2 check-role-of-redis](https://user-images.githubusercontent.com/3222837/63569170-31fd1c00-c5b3-11e9-96a7-c14383825652.png)

## Test Configured redis-ha
Redis 가 구성된 redis-ha namespace 와 다른 namespace 에 redis-client 를 구성한다.
(사실, redis-cli 만 설치되어 있음 된다.) 

### 1. Installing the chart for Redis-client

![redis-ha_6 configure-client](https://user-images.githubusercontent.com/3222837/63569182-404b3800-c5b3-11e9-925b-06e707cf6c41.png)

### 2. Execute commands of redis-cli for getting/setting key:value.
한 노드에 접속해 앞서 구성한 redis-ha 의 Headless service 를 통해 request 를 보낸다.

![redis-ha_7 execute-client-for-test](https://user-images.githubusercontent.com/3222837/63569377-0c244700-c5b4-11e9-8988-9a07bde1cc81.png)

## Test failover to configured Redis-ha

### 1. Give the master a sleep and stop the movement for a moment.

![redis-ha_8 execute-sleep-on-master-for-failover-test](https://user-images.githubusercontent.com/3222837/63569428-4b529800-c5b4-11e9-8661-63a0a01a3db8.png)


### 2. Check the changed role of each redis node.

![redis-ha_9-1 check-changed-role-from-master-to-slave-for-failover-test](https://user-images.githubusercontent.com/3222837/63569526-a2586d00-c5b4-11e9-93c0-8a0f9febd74b.png)

![redis-ha_9-2 check-changed-role-from-slave-to-master-for-failover-test](https://user-images.githubusercontent.com/3222837/63569575-e3508180-c5b4-11e9-9e5b-489372ac6350.png)

### 3. Check if Redis operates normally. 

![redis-ha_9-3 check-the-behavior-by-execute-client-for-failover-test](https://user-images.githubusercontent.com/3222837/63569584-efd4da00-c5b4-11e9-9942-be482f8894b3.png)

## Test failover-back to configured Redis-ha

![redis-ha_10-1 execute-failover-back-and-check-changed-role-for-failover-test](https://user-images.githubusercontent.com/3222837/63569646-362a3900-c5b5-11e9-91ea-33c390fb636d.png)

![redis-ha_10-2 execute-failover-back-and-check-changed-role-for-failover-test](https://user-images.githubusercontent.com/3222837/63569649-375b6600-c5b5-11e9-89e5-33e15bc13b87.png)

## You can add config's option on redis.conf if you want to add configuration values.
redis-values-*.yaml 파일의 redis.config 필드에 추가하면 됩니다. 다음과 같이:
```
redis:
  config:
    tcp-keepalive: 300
    pidfile: /var/run/redis.pid
    loglevel: debug
    logfile: /data/redis.log
    maxclients: 100000
    save: "900 1"
    repl-diskless-sync: "yes"
    rdbcompression: "yes"
    rdbchecksum: "yes"
    min-slaves-to-write: 1
    min-slaves-max-lag: 5   # Value in seconds
    maxmemory: "0"       # Max memory to use for each redis instance. Default is unlimited.
    maxmemory-policy: "volatile-lru"
```

