# Chapter 10: Kubernetes Storage, ConfigMaps, & Secrets

In modern cloud-native architectures, decoupling application logic from persistence and operational state is a core tenant of resilient platform engineering. This chapter covers the implementation, lifecycle management, and security patterns of Kubernetes persistent storage primitives, Container Storage Interface (CSI) drivers, environment configuration management, and secrets management using both native primitives and external secrets stores (such as HashiCorp Vault) as aligned with the LPI 701-200 exam standards.

## 10.1 PersistentVolumes (PV), PersistentVolumeClaims (PVC), and Dynamic Provisioning

Kubernetes separates storage allocation from infrastructure consumption through two API resources: `PersistentVolume` (PV) and `PersistentVolumeClaim` (PVC).

### Storage Lifecycle Architecture


![Kubernetes Storage binding model](assets/images/chapter10/10-1-STORAGE-BINDING-AND-LIFECYCLE.png)

### Storage Reclamation Policies

When a user deletes a PVC bound to a PV, the reclaim policy defined on the PV tells the cluster how to treat the underlying physical storage asset:

![Kubernetes PV Reclaim Policies](assets/images/chapter10/10-1-STORAGE-RECLAIM-POLICIES.png)

### Access Modes

Access modes define how many nodes can concurrently mount a given PV:

1. `ReadWriteOnce` (`RWO`): Volume can be mounted as read-write by a single node.
2. `ReadOnlyMany` (`ROX`): Volume can be mounted as read-only by many nodes concurrently.
3. `ReadWriteMany` (`RWX`): Volume can be mounted as read-write by many nodes concurrently (requires distributed file storage like NFS, CephFS, or Gluster).
4. `ReadWriteOncePod` (`RWOP`): Volume can be mounted as read-write by a single Pod across the entire cluster (CSI-specific).

### Dynamic Provisioning Manifests

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: enterprise-ssd
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
allowVolumeExpansion: true
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-state-pvc
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: enterprise-ssd
  resources:
    requests:
      storage: 50Gi
```

## 10.2 Container Storage Interface (CSI) Drivers

The Container Storage Interface (CSI) standardizes the out-of-tree interface between storage vendors and container orchestrators.

### CSI Driver Subsystem Architecture

![CSI Driver Subsystem Architecture](assets/images/chapter10/10-2-CSI-SUBSYSTEM-TOPOLOGY.png)
### CSI RPC Methods Breakdown

1. **CSI Controller Service**:
   * `CreateVolume()` / `DeleteVolume()`: Provisions or deprovisions storage assets on the storage vendor's SAN/NAS API.
   * `ControllerPublishVolume()` / `ControllerUnpublishVolume()`: Attaches/detaches block storage to a specific target host machine (e.g., AWS EBS `AttachVolume`).

2. **CSI Node Service**:
   * `NodeStageVolume()`: Formats the block device with a file system (`ext4`, `xfs`) and mounts it to a global staging directory.
   * `NodePublishVolume()`: Bind-mounts the staged volume into the container's isolated mount namespace (`/var/lib/kubelet/pods/<pod-uid>/volumes/...`).

## 10.3 Decoupling Configuration using ConfigMaps

ConfigMaps store non-confidential configuration data as key-value pairs, decoupling application binaries from platform configuration.

![Kubernetes PV Reclaim Policies](assets/images/chapter10/10-3-CONFIGMAP-CONSUMPTION-PATTERNS.png)

### Production ConfigMap Manifest with Multi-Pattern Consumption

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-gateway-config
  namespace: production
data:
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "10000"
  app-spec.yaml: |
    server:
      port: 8080
      timeout: 30s
    database:
      pool_size: 20
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: gateway
        image: registry.enterprise.internal/apps/gateway:v1.4.0
        env:
        - name: SYSTEM_LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: api-gateway-config
              key: LOG_LEVEL
        volumeMounts:
        - name: config-volume
          mountPath: /etc/gateway/config
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: api-gateway-config
          items:
          - key: app-spec.yaml
            path: app-spec.yaml
```

## 10.4 Managing Sensitive Data with Kubernetes Secrets and External Secret Store Integration

Kubernetes Secrets handle sensitive data such as passwords, API keys, and TLS certificates.

### Built-In Secret Types

![Kubernetes Built-In Secret Types](assets/images/chapter10/10-4-BUILT-IN-SECRET-TYPES.png)
### Native Secrets Security Limitations

1. **Base64 Encoding**: Native Secret objects are only base64-encoded, **not encrypted**, when stored or queried unless Encryption at Rest is explicitly configured on the API server.
2. **etcd Exposure**: Plaintext secrets exist in the etcd datastore unless encrypted using `EncryptionConfiguration` with a provider key (`kms`, `aescbc`, `secretbox`).

### External Secrets Operator (ESO) & Vault Integration Architecture

![External Secrets Operator](assets/images/chapter10/10-4-EXTERNAL-SECRETS-INTEGRATION-FLOW.png)

## 10.5 Hands-On Lab: Provisioning Ceph CSI Persistent Volumes with External HashiCorp Vault Secrets

### Objective

Deploy an enterprise-grade setup consisting of a Ceph CSI StorageClass for dynamic storage provisioning, along with the External Secrets Operator (ESO) syncing sensitive credentials from HashiCorp Vault into native Kubernetes Secrets.

![Hands-on lab architecture diagram](assets/images/chapter10/10-5-LAB-ARCHITECTURE-TARGET.png)

### Step 1: Configure Namespace and StorageClass for Ceph CSI

```bash
kubectl create namespace lab-storage-sec

cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-rbd-sc
  namespace: lab-storage-sec
provisioner: rbd.csi.ceph.com
fstype: ext4
parameters:
  clusterID: 4b1715f4-210e-46b7-8025-a129d2b2c45f
  pool: rbd-k8s-pool
  imageFormat: "2"
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: csi-ceph-secret
  csi.storage.k8s.io/provisioner-secret-namespace: lab-storage-sec
  csi.storage.k8s.io/node-stage-secret-name: csi-ceph-secret
  csi.storage.k8s.io/node-stage-secret-namespace: lab-storage-sec
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
EOF
```

### Step 2: Configure HashiCorp Vault Authentication and Secret Store

```bash
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: lab-storage-sec
spec:
  provider:
    vault:
      server: "https://vault.enterprise.internal:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "lab-storage-role"
          secretRef:
            name: vault-auth-token
            key: token
EOF
```

### Step 3: Map Vault Secret to Native Kubernetes Secret via ExternalSecret

```bash
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials-es
  namespace: lab-storage-sec
spec:
  refreshInterval: "1h"
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
  - secretKey: DB_PASSWORD
    remoteRef:
      key: production/database
      property: password
  - secretKey: DB_USER
    remoteRef:
      key: production/database
      property: username
EOF
```

### Step 4: Provision Workload Consuming Ceph PV and Synchronized Secret

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-data-pvc
  namespace: lab-storage-sec
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ceph-rbd-sc
  resources:
    requests:
      storage: 20Gi

apiVersion: v1
kind: Pod
metadata:
  name: stateful-db-0
  namespace: lab-storage-sec
spec:
  containers:
  - name: postgres
    image: postgres:15-alpine
    env:
    - name: POSTGRES_USER
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: DB_USER
    - name: POSTGRES_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: DB_PASSWORD
    volumeMounts:
    - name: storage-volume
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: storage-volume
    persistentVolumeClaim:
      claimName: db-data-pvc
EOF
```

### Step 5: Verification and Inspection

```bash
# 1. Verify ExternalSecret synchronization status with Vault
kubectl get externalsecret db-credentials-es -n lab-storage-sec

# 2. Inspect generated native Kubernetes Secret key data
kubectl get secret db-credentials -n lab-storage-sec -o jsonpath='{.data}'

# 3. Verify PVC status and binding to dynamically provisioned Ceph PV
kubectl get pvc db-data-pvc -n lab-storage-sec

# 4. Confirm volume mount status inside active Pod namespace
kubectl exec -it stateful-db-0 -n lab-storage-sec -- df -h /var/lib/postgresql/data
```

## 10.6 Chapter Review and Operational Checklist

Before moving forward, ensure proficiency in the following key domain concepts:

```
* [ ] Understanding PV access modes (`RWO`, `ROX`, `RWX`, `RWOP`) and reclaim policies (`Retain`, `Delete`).
* [ ] Differentiating between in-tree volume plugins and out-of-tree CSI driver RPC operations (`CreateVolume`, `NodeStageVolume`, `NodePublishVolume`).
* [ ] Utilizing ConfigMaps via Environment Variables, `envFrom`, and volume mounts.
* [ ] Managing Kubernetes Secrets security constraints, base64 encoding mechanics, and etcd encryption at rest.
* [ ] Integrating external secrets stores using operators (e.g., External Secrets Operator with HashiCorp Vault).
```

### Summary of Generated Files

- **`Chapter10.md`**: Enterprise-grade guide covering persistent storage, CSI driver architecture, ConfigMaps, Secrets, External Secrets Operator (ESO), HashiCorp Vault integration, and a production lab environment with Ceph CSI.
  
