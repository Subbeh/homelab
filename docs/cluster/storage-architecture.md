# Storage Architecture

## Overview

The cluster implements a multi-tiered storage architecture combining distributed block storage, network-attached storage, and automated backup systems to provide redundant, scalable, and resilient data persistence.

## Storage Components

### Rook-Ceph Distributed Storage

**Purpose**: Primary persistent storage for stateful applications requiring high availability and performance.

**Architecture**:
- **Cluster Configuration**: 3-node Ceph cluster deployed via Rook operator
- **OSD Deployment**: One OSD per Kubernetes node using node-local storage
- **Resource Constraints**: 
  - Manager: 250m CPU, 512Mi memory (1Gi limit)
  - Monitor: 250m CPU, 512Mi memory (1Gi limit)  
  - OSD: 250m CPU, 2Gi memory (4Gi limit)

**Storage Classes**:
- `ceph-block`: RBD (RADOS Block Device) for persistent volumes
- Used by: Prometheus storage, Alertmanager storage, application databases

**High Availability**:
- 3-way replication across cluster nodes
- Automatic failover and recovery
- Self-healing capabilities

### VolSync Backup & Replication

**Purpose**: Automated backup, snapshot, and cross-cluster replication for critical data.

**Architecture**:
- **Backend**: Restic repository for deduplication and encryption
- **Secret Management**: External Secrets Operator with Vault integration
- **Scheduling**: CronJob-based snapshot creation
- **Scaling**: KEDA HPA for dynamic workload scaling

**Key Features**:
- Incremental backups with deduplication
- Encryption at rest and in transit
- Cross-cluster replication capabilities
- Point-in-time recovery

**Configuration Template**:
```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: "${APP}-volsync"
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: vault
  target:
    name: "${APP}-volsync-secret"
    template:
      data:
        RESTIC_REPOSITORY: "/repository/${APP}"
        RESTIC_PASSWORD: "{{ .RESTIC_PASSWORD }}"
```

### NFS Network Storage

**Purpose**: Shared storage for legacy applications and cross-node file sharing.

**Architecture**:
- **NAS Integration**: External NAS server at `192.168.80.100`
- **K8S Endpoint**: Accessible via `nas-k8s.sbbh.cloud` (10.11.80.100)
- **Network Path**: K8S → OPNsense → NAS via dedicated network routes
- **Access Control**: Firewall rules for port 2049 (NFS) access

**Use Cases**:
- Shared configuration files
- Application data requiring POSIX filesystem semantics
- Legacy application migration

### KEDA Event-Driven Autoscaling

**Purpose**: Dynamic scaling of storage-related workloads based on metrics and events.

**Architecture**:
- **Metrics Server**: Integration with Prometheus for custom metrics
- **Scalers**: Support for various event sources (Prometheus, Cron, etc.)
- **Feature Gates**: MutatingAdmissionPolicy enabled in Talos for advanced policies

**Scaling Targets**:
- VolSync backup jobs
- Storage migration workloads
- Data processing pipelines

**Configuration Requirements**:
```yaml
# Talos patch for KEDA support
feature-gates: MutatingAdmissionPolicy=true
```

## Storage Workflows

### Application Deployment with Persistent Storage

1. **PVC Creation**: Application requests storage via PersistentVolumeClaim
2. **Dynamic Provisioning**: Ceph CSI driver creates RBD volume
3. **Volume Attachment**: Kubernetes schedules pod with attached storage
4. **Backup Scheduling**: VolSync creates automated backup schedule
5. **Monitoring**: Prometheus collects storage metrics and alerts

### Backup and Recovery Process

1. **Snapshot Creation**: VolSync creates point-in-time snapshots
2. **Restic Backup**: Incremental backup to repository with deduplication
3. **Validation**: Backup integrity verification
4. **Replication**: Optional cross-cluster replication for DR
5. **Recovery**: Point-in-time restore from backup repository

### Storage Migration

1. **Source Identification**: Identify volumes requiring migration
2. **VolSync Configuration**: Set up replication source and destination
3. **Initial Sync**: Full volume copy to destination
4. **Incremental Sync**: Delta synchronization for consistency
5. **Cutover**: Application restart with new storage backend

## Monitoring and Alerting

### Ceph Cluster Monitoring

**Metrics Collected**:
- Cluster health status (HEALTH_OK, HEALTH_WARN, HEALTH_ERR)
- OSD status and utilization
- Pool usage and performance
- PG (Placement Group) distribution

**Grafana Dashboards**:
- Ceph Cluster Overview (GrafanaID: 2842)
- Ceph OSD Single (GrafanaID: 5336)  
- Ceph Pools (GrafanaID: 5342)

**Alert Rules**:
```yaml
- alert: CephMgrModuleCrash
  expr: ceph_health_status != 0
  labels:
    severity: critical
```

### VolSync Monitoring

**Metrics Collected**:
- Backup job success/failure rates
- Repository size and growth
- Replication lag and status
- Recovery point objectives (RPO)

**Grafana Dashboard**:
- VolSync Dashboard (GrafanaID: 21356)

### Storage Capacity Monitoring

**Metrics Tracked**:
- PVC utilization across namespaces
- Ceph cluster capacity and usage
- NFS mount availability and performance
- Storage class performance metrics

## Security Considerations

### Encryption

**At Rest**:
- Ceph OSD encryption using dm-crypt
- Restic repository encryption with AES-256
- Secret encryption in etcd

**In Transit**:
- TLS encryption for Ceph mon/mgr communication
- Encrypted backup transport to repositories
- Vault TLS for secret retrieval

### Access Control

**RBAC Policies**:
- Namespace-scoped storage access
- ServiceAccount-based permissions
- Operator-level cluster admin rights

**Network Policies**:
- Ceph traffic isolation within cluster
- NFS access restricted to authorized pods
- Vault communication over secure channels

### Secret Management

**External Secrets Integration**:
- Vault backend for Restic credentials
- Automatic secret rotation capabilities
- Template-based secret generation

**Backup Encryption Keys**:
- Vault-managed encryption keys
- Key rotation policies
- Recovery key escrow procedures

## Performance Characteristics

### Ceph Performance

**Typical Metrics**:
- Random Read: ~15,000 IOPS per OSD
- Random Write: ~5,000 IOPS per OSD  
- Sequential Read: ~200 MB/s per OSD
- Sequential Write: ~150 MB/s per OSD

**Optimization**:
- SSD-based OSDs for performance workloads
- Separate journal/WAL devices for write optimization
- Tuned CPU/memory limits for resource efficiency

### VolSync Performance

**Backup Characteristics**:
- Initial backup: Full volume copy
- Incremental backups: Changed blocks only
- Deduplication ratio: ~70% typical reduction
- Network bandwidth: Limited by repository connection

### NFS Performance

**Network Characteristics**:
- 1Gbps network interconnect
- NFSv4 with Kerberos authentication
- Caching for frequently accessed files
- Concurrent access limitations

## Troubleshooting Guide

### Common Ceph Issues

**OSD Down/Out**:
```bash
# Check OSD status
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph osd status

# Restart problematic OSD
kubectl delete pod -n rook-ceph -l app=rook-ceph-osd,ceph_daemon_id=X
```

**Manager Module Crashes**:
```bash
# Check manager status
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph mgr module ls

# Acknowledge alerts
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph health mute <alert-type>
```

### VolSync Issues

**Backup Failures**:
```bash
# Check VolSync logs
kubectl logs -n volsync-system deployment/volsync-controller

# Verify secret availability
kubectl get secret -n <namespace> <app>-volsync-secret -o yaml
```

**Repository Access**:
```bash
# Test repository connectivity
kubectl exec -it <volsync-pod> -- restic -r <repo> snapshots
```

### Storage Capacity Issues

**PVC Expansion**:
```bash
# Expand existing PVC
kubectl patch pvc <pvc-name> -p '{"spec":{"resources":{"requests":{"storage":"<new-size>"}}}}'

# Monitor expansion progress  
kubectl describe pvc <pvc-name>
```

**Ceph Capacity**:
```bash
# Check cluster usage
kubectl exec -n rook-ceph deploy/rook-ceph-tools -- ceph df

# Add new OSD (requires new node or disk)
# Update CephCluster CR with additional storage devices
```

## Future Enhancements

### Short Term (1-3 months)
- OpenEBS integration for local storage optimization
- Enhanced backup retention policies
- Cross-cluster disaster recovery testing
- Storage performance benchmarking

### Medium Term (3-6 months)  
- Multi-zone Ceph deployment
- S3-compatible object storage via Ceph RGW
- Application-aware backup policies
- Storage tiering (SSD/HDD) implementation

### Long Term (6+ months)
- Multi-cluster storage federation
- AI/ML workload storage optimization
- Edge storage integration
- Compliance and audit logging