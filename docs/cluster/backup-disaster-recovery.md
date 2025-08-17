# Backup & Disaster Recovery

## Overview

The cluster implements a comprehensive backup and disaster recovery strategy using VolSync for automated backup, replication, and point-in-time recovery capabilities. This system provides data protection across multiple failure scenarios while maintaining RPO (Recovery Point Objective) and RTO (Recovery Time Objective) targets.

## Architecture

### VolSync Components

**VolSync Operator**:
- **Purpose**: Manages backup and replication workflows for persistent volumes
- **Deployment**: Single controller with high availability support
- **Backend**: Restic repository for deduplication and encryption
- **Scaling**: KEDA integration for dynamic resource allocation

**Replication Sources**:
- **Volume Snapshots**: Point-in-time copies of persistent volumes
- **Incremental Backups**: Changed block replication for efficiency
- **Cross-Cluster**: Replication to remote clusters for disaster recovery

**Replication Destinations**:
- **Repository Storage**: Encrypted backup repositories
- **Remote Clusters**: Live replication to secondary sites
- **Object Storage**: S3-compatible storage backends

### Integration Points

**External Secrets Operator**:
- **Purpose**: Secure credential management for backup repositories
- **Vault Backend**: HashiCorp Vault integration for secret retrieval
- **Template System**: Dynamic secret generation per application

**Storage Integration**:
- **Ceph RBD**: Primary storage backend for application data
- **NFS**: Legacy application backup support
- **Local Storage**: Node-local persistent volume backup

**KEDA Autoscaling**:
- **Backup Scaling**: Dynamic resource allocation during backup windows
- **Queue Processing**: Parallel backup job execution
- **Resource Optimization**: Scale down during idle periods

## Backup Strategy

### Application-Level Backups

**Per-Application Configuration**:
```yaml
# Example VolSync configuration template
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
  dataFrom:
    - extract:
        key: volsync-template
```

**Backup Scheduling**:
- **Daily Backups**: Automated daily snapshots for all applications
- **Weekly Full Backups**: Complete volume backup for long-term retention
- **Pre-Maintenance**: Backup before cluster maintenance activities
- **Event-Driven**: Backups triggered by application events

### Data Classification

**Critical Data (RPO: 1 hour, RTO: 15 minutes)**:
- Database persistent volumes
- Configuration data and secrets
- User-generated content
- Application state and sessions

**Important Data (RPO: 4 hours, RTO: 1 hour)**:
- Application logs and metrics
- Temporary processing data
- Cache and optimization data
- Development and testing data

**Archival Data (RPO: 24 hours, RTO: 4 hours)**:
- Historical logs and metrics
- Completed backup sets
- Audit trails and compliance data
- Documentation and static content

## Backup Workflows

### Snapshot Creation

**Volume Snapshot Process**:
1. **Pre-Backup Hook**: Application quiesce and consistency check
2. **Snapshot Creation**: CSI snapshot of persistent volume
3. **Backup Job**: VolSync creates backup job from snapshot
4. **Repository Upload**: Encrypted data transfer to backup repository
5. **Cleanup**: Temporary snapshot and job resource cleanup

**Snapshot Configuration**:
```yaml
apiVersion: volsync.backube/v1alpha1
kind: ReplicationSource
metadata:
  name: example-app-backup
spec:
  sourcePVC: example-app-data
  trigger:
    schedule: "0 2 * * *"  # Daily at 2 AM
  restic:
    repository: example-app-volsync-secret
    retain:
      daily: 7
      weekly: 4
      monthly: 12
    copyMethod: Snapshot
    volumeSnapshotClassName: ceph-block
```

### Cross-Cluster Replication

**Disaster Recovery Replication**:
```yaml
apiVersion: volsync.backube/v1alpha1
kind: ReplicationDestination
metadata:
  name: example-app-dr
  namespace: disaster-recovery
spec:
  trigger:
    schedule: "0 */6 * * *"  # Every 6 hours
  restic:
    repository: example-app-dr-secret
    destinationPVC: example-app-dr-data
    capacity: 50Gi
    storageClassName: ceph-block
    accessModes:
      - ReadWriteOnce
```

**Multi-Site Architecture**:
- **Primary Site**: Production cluster with active workloads
- **Secondary Site**: Disaster recovery cluster with replicated data
- **Backup Repository**: External storage for long-term retention
- **Network Connectivity**: VPN or dedicated links between sites

## Repository Management

### Restic Backend Configuration

**Repository Structure**:
```
/backup-repository/
├── applications/
│   ├── app1/
│   │   ├── snapshots/
│   │   ├── data/
│   │   └── index/
│   └── app2/
│       ├── snapshots/
│       ├── data/
│       └── index/
└── infrastructure/
    ├── etcd/
    ├── persistent-volumes/
    └── configuration/
```

**Encryption Configuration**:
- **Repository Encryption**: AES-256 encryption for all backup data
- **Key Management**: Vault-managed encryption keys with rotation
- **Transport Security**: TLS encryption for data in transit
- **Access Control**: Repository-level access controls and authentication

### Storage Backends

**S3-Compatible Storage**:
```yaml
# Restic repository configuration
RESTIC_REPOSITORY: "s3:https://backup-storage.example.com/bucket/path"
AWS_ACCESS_KEY_ID: "{{ .access_key }}"
AWS_SECRET_ACCESS_KEY: "{{ .secret_key }}"
RESTIC_PASSWORD: "{{ .repository_password }}"
```

**Local Storage Integration**:
```yaml
# NFS-backed repository
RESTIC_REPOSITORY: "/mnt/backup-nfs/repositories/${APP}"
RESTIC_PASSWORD: "{{ .repository_password }}"
```

**Network Storage**:
- **NAS Integration**: Direct NFS mount for backup storage
- **Object Storage**: S3/MinIO compatible object storage
- **Block Storage**: iSCSI or FC attached storage for repositories

## Recovery Procedures

### Point-in-Time Recovery

**Recovery Process**:
1. **Recovery Planning**: Identify recovery point and target environment
2. **Repository Access**: Authenticate and connect to backup repository
3. **Snapshot Selection**: Choose appropriate backup snapshot
4. **Volume Creation**: Create new persistent volume for recovery
5. **Data Restoration**: Restore data from backup to new volume
6. **Application Restart**: Deploy application with recovered data

**Recovery Commands**:
```bash
# List available snapshots
kubectl exec -it <volsync-pod> -- restic -r <repository> snapshots

# Restore specific snapshot
kubectl exec -it <volsync-pod> -- restic -r <repository> restore <snapshot-id> --target /restore

# Verify restoration
kubectl exec -it <volsync-pod> -- restic -r <repository> check
```

### Disaster Recovery Scenarios

**Complete Cluster Loss**:
1. **Infrastructure Rebuild**: Provision new cluster infrastructure
2. **Core Services**: Deploy Flux, External Secrets, VolSync operators
3. **Secret Recovery**: Restore Vault credentials and repository access
4. **Data Recovery**: Restore all application data from repositories
5. **Application Deployment**: Deploy applications with recovered data
6. **Validation**: Verify application functionality and data integrity

**Partial Data Loss**:
1. **Impact Assessment**: Identify affected applications and data
2. **Isolation**: Prevent further data corruption or loss
3. **Selective Recovery**: Restore only affected persistent volumes
4. **Consistency Check**: Verify data consistency across applications
5. **Service Restoration**: Restart affected services with recovered data

**Node Failure Recovery**:
1. **Automatic Failover**: Kubernetes reschedules pods to healthy nodes
2. **Data Verification**: Check persistent volume integrity
3. **Backup Validation**: Ensure recent backups are available
4. **Monitoring**: Enhanced monitoring during recovery period

## Monitoring & Alerting

### Backup Health Monitoring

**Prometheus Metrics**:
```promql
# Backup job success rate
rate(volsync_backup_jobs_completed_total{status="success"}[1h]) / rate(volsync_backup_jobs_total[1h])

# Backup duration trends
histogram_quantile(0.95, rate(volsync_backup_duration_seconds_bucket[24h]))

# Repository size growth
increase(volsync_repository_size_bytes[7d])

# Failed backup alert
volsync_backup_jobs_completed_total{status="failed"} > 0
```

**Alert Rules**:
```yaml
groups:
  - name: backup-alerts
    rules:
      - alert: BackupJobFailed
        expr: volsync_backup_jobs_completed_total{status="failed"} > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Backup job failed for {{ $labels.app }}"
          
      - alert: BackupMissing
        expr: time() - volsync_last_backup_timestamp > 86400
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "No backup in 24 hours for {{ $labels.app }}"
          
      - alert: RepositoryConnectionFailed
        expr: volsync_repository_connection_failures > 3
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "Cannot connect to backup repository for {{ $labels.repository }}"
```

### Recovery Testing

**Automated Recovery Tests**:
```yaml
# Monthly DR test job
apiVersion: batch/v1
kind: CronJob
metadata:
  name: dr-test
spec:
  schedule: "0 3 1 * *"  # First day of month at 3 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: dr-test
            image: volsync-test:latest
            command:
            - /scripts/dr-test.sh
            env:
            - name: TEST_NAMESPACE
              value: "dr-testing"
            - name: REPOSITORY_SECRET
              valueFrom:
                secretKeyRef:
                  name: dr-test-secret
                  key: repository-url
```

**Test Scenarios**:
- **Complete Application Recovery**: Full recovery simulation
- **Partial Data Recovery**: Selective volume restoration
- **Cross-Cluster Replication**: Remote site recovery testing
- **Performance Testing**: Recovery time measurement

## Security & Compliance

### Encryption Standards

**Data Encryption**:
- **AES-256**: Repository encryption with strong key derivation
- **TLS 1.3**: Transport encryption for all backup traffic
- **Key Rotation**: Quarterly encryption key rotation
- **Zero-Knowledge**: Repository providers cannot access backup data

**Access Control**:
```yaml
# RBAC for backup operations
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: backup-operator
rules:
- apiGroups: ["volsync.backube"]
  resources: ["replicationsources", "replicationdestinations"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims", "secrets"]
  verbs: ["get", "list", "create"]
```

### Compliance Requirements

**Data Retention**:
- **Operational**: 7 daily, 4 weekly, 12 monthly snapshots
- **Compliance**: Long-term retention per regulatory requirements
- **Legal Hold**: Backup retention during litigation or audits
- **Secure Deletion**: Cryptographic erasure of expired backups

**Audit Trail**:
- **Backup Events**: Complete log of all backup operations
- **Access Logging**: Repository access and recovery activities
- **Change Tracking**: Modifications to backup policies and schedules
- **Compliance Reporting**: Regular backup and recovery reports

## Performance Optimization

### Backup Windows

**Scheduling Strategy**:
- **Off-Peak Hours**: Schedule backups during low-activity periods
- **Staggered Backups**: Spread backup jobs across time to reduce load
- **Priority Queuing**: Critical applications get backup priority
- **Resource Throttling**: Limit backup impact on production workloads

**KEDA Scaling Integration**:
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: volsync-backup-scaler
spec:
  scaleTargetRef:
    name: volsync-controller
  minReplicaCount: 1
  maxReplicaCount: 5
  triggers:
    - type: cron
      metadata:
        timezone: UTC
        start: "0 2 * * *"    # Scale up for backup window
        end: "0 6 * * *"      # Scale down after backups
        desiredReplicas: "3"
    - type: prometheus
      metadata:
        serverAddress: http://prometheus-operated.observability.svc.cluster.local:9090
        metricName: volsync_backup_queue_depth
        threshold: '5'
        query: sum(volsync_pending_backup_jobs)
```

### Network Optimization

**Bandwidth Management**:
- **Quality of Service**: Network QoS for backup traffic
- **Compression**: Restic deduplication and compression
- **Incremental Transfers**: Only changed blocks transferred
- **Parallel Uploads**: Multiple concurrent backup streams

**Repository Optimization**:
- **Local Caching**: Repository cache for faster access
- **Deduplication**: Block-level deduplication across applications
- **Compression**: Adaptive compression based on data type
- **Garbage Collection**: Regular cleanup of unused backup data

## Operational Procedures

### Backup Validation

**Daily Checks**:
```bash
# Verify backup completion
kubectl get replicationsources -A --no-headers | while read ns name rest; do
  kubectl get replicationsource $name -n $ns -o jsonpath='{.status.lastSyncTime}'
done

# Check repository integrity
kubectl exec -n volsync-system deployment/volsync-controller -- \
  restic -r $REPOSITORY check --read-data-subset=1%
```

**Weekly Validation**:
- **Recovery Testing**: Test restore procedures for critical applications
- **Performance Monitoring**: Backup duration and throughput analysis
- **Capacity Planning**: Repository growth and retention policy review
- **Security Audit**: Access logs and encryption status review

### Incident Response

**Backup Failure Response**:
1. **Alert Triage**: Categorize failure severity and impact
2. **Root Cause Analysis**: Investigate backup failure causes
3. **Immediate Action**: Manual backup initiation if critical
4. **Resolution**: Fix underlying issues and verify restoration
5. **Post-Incident**: Review and improve backup procedures

**Data Recovery Response**:
1. **Impact Assessment**: Determine scope of data loss
2. **Recovery Planning**: Select appropriate recovery point
3. **Stakeholder Communication**: Notify affected teams and users
4. **Recovery Execution**: Restore data following procedures
5. **Verification**: Validate recovered data integrity and completeness

## Future Enhancements

### Short Term (1-3 months)
- **Cross-Cloud Replication**: Multi-cloud backup repositories
- **Application-Aware Backups**: Database-specific backup procedures
- **Enhanced Monitoring**: Backup quality and consistency metrics
- **Automated Testing**: Continuous recovery validation

### Medium Term (3-6 months)
- **Geo-Distributed Backups**: Multiple geographic backup locations
- **Backup Analytics**: ML-driven backup optimization
- **Compliance Automation**: Automated compliance reporting
- **Cost Optimization**: Intelligent retention and storage tiering

### Long Term (6+ months)
- **Zero-Downtime Recovery**: Live migration from backups
- **Quantum-Safe Encryption**: Post-quantum cryptography adoption
- **AI-Driven Recovery**: Intelligent recovery point selection
- **Immutable Infrastructure**: GitOps-driven disaster recovery