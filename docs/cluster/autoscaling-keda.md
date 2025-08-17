# Autoscaling with KEDA

## Overview

KEDA (Kubernetes Event-Driven Autoscaling) provides event-driven autoscaling capabilities for the cluster, enabling dynamic scaling of applications and workloads based on external metrics, events, and custom triggers beyond traditional CPU/memory-based HPA.

## Architecture

### KEDA Components

**KEDA Operator**:
- **Purpose**: Core controller managing ScaledObjects and ScaledJobs
- **Deployment**: Single instance with leader election
- **CRDs**: ScaledObject, ScaledJob, TriggerAuthentication, ClusterTriggerAuthentication

**Metrics Server**:
- **Purpose**: Exposes custom metrics to Kubernetes HPA
- **Integration**: Kubernetes Metrics API adapter
- **Scaling**: Provides scaling metrics for HPA decisions

**Admission Webhooks**:
- **Purpose**: Validation and mutation of KEDA resources
- **Requirements**: MutatingAdmissionPolicy feature gate enabled
- **Security**: TLS-secured webhook endpoints

### Talos Configuration

**Feature Gate Enablement**:
```yaml
# Required Talos patch for KEDA functionality
feature-gates: MutatingAdmissionPolicy=true
```

**Applied To**: All control plane nodes for admission webhook support

## Scaling Strategies

### HPA Integration

**Traditional vs KEDA HPA**:
- **Traditional HPA**: CPU/Memory metrics only
- **KEDA HPA**: External metrics, events, queues, databases
- **Coexistence**: KEDA manages HPA with external metrics

**ScaledObject Configuration**:
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: example-scaledobject
spec:
  scaleTargetRef:
    name: example-deployment
  minReplicaCount: 1
  maxReplicaCount: 10
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus-operated.observability.svc.cluster.local:9090
        metricName: example_queue_size
        threshold: '10'
        query: sum(example_queue_length)
```

### Event-Driven Scaling

**Supported Event Sources**:
- **Prometheus Metrics**: Custom application metrics
- **Message Queues**: RabbitMQ, Apache Kafka, Azure Service Bus
- **Databases**: PostgreSQL, MongoDB, Redis
- **HTTP**: Webhook-based scaling triggers
- **Cron**: Time-based scaling schedules

**ScaledJob Configuration**:
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledJob
metadata:
  name: batch-processor
spec:
  jobTargetRef:
    template:
      spec:
        containers:
        - name: processor
          image: batch-processor:latest
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus-operated.observability.svc.cluster.local:9090
        metricName: pending_jobs
        threshold: '5'
        query: sum(queue_pending_jobs)
```

## Current Implementation

### VolSync Integration

**Use Case**: Dynamic scaling of backup and replication workloads based on backup queue size and repository status.

**Scaling Triggers**:
- **Backup Queue Length**: Scale when backup jobs accumulate
- **Repository Size**: Adjust resources based on data volume
- **Schedule-Based**: Pre-scale before scheduled backup windows
- **Error Rate**: Scale up for retry operations

**Configuration Example**:
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: volsync-backup-scaler
  namespace: volsync-system
spec:
  scaleTargetRef:
    name: volsync-backup-controller
  minReplicaCount: 1
  maxReplicaCount: 5
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus-operated.observability.svc.cluster.local:9090
        metricName: volsync_pending_backups
        threshold: '3'
        query: sum(volsync_backup_jobs_pending)
    - type: cron
      metadata:
        timezone: UTC
        start: "0 2 * * *"    # Scale up at 2 AM for backup window
        end: "0 6 * * *"      # Scale down at 6 AM after backups
        desiredReplicas: "3"
```

### Storage Workload Scaling

**Ceph Management Scaling**:
- **OSD Operations**: Scale during maintenance windows
- **Rebalancing**: Additional resources during cluster rebalancing
- **Recovery**: Enhanced capacity during failure recovery

**Example Configuration**:
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: ceph-mgr-scaler
  namespace: rook-ceph
spec:
  scaleTargetRef:
    name: rook-ceph-mgr
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus-operated.observability.svc.cluster.local:9090
        metricName: ceph_recovery_rate
        threshold: '0.1'
        query: sum(rate(ceph_osd_recovery_ops[5m]))
```

## Scaling Patterns

### Predictive Scaling

**Schedule-Based Scaling**:
```yaml
triggers:
  - type: cron
    metadata:
      timezone: "America/New_York"
      start: "0 8 * * 1-5"     # Scale up weekday mornings
      end: "0 18 * * 1-5"      # Scale down weekday evenings
      desiredReplicas: "5"
```

**Event-Driven Scaling**:
```yaml
triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-operated.observability.svc.cluster.local:9090
      metricName: app_request_rate
      threshold: '100'
      query: sum(rate(http_requests_total[1m]))
```

### Batch Job Scaling

**Queue-Based Processing**:
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledJob
metadata:
  name: queue-processor
spec:
  jobTargetRef:
    template:
      spec:
        containers:
        - name: worker
          image: queue-worker:latest
        restartPolicy: OnFailure
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus-operated.observability.svc.cluster.local:9090
        metricName: queue_depth
        threshold: '10'
        query: sum(queue_messages_ready)
  maxReplicaCount: 20
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

### Multi-Trigger Scaling

**Combined Triggers**:
```yaml
triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-operated.observability.svc.cluster.local:9090
      metricName: cpu_utilization
      threshold: '70'
      query: avg(cpu_usage_percent)
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-operated.observability.svc.cluster.local:9090
      metricName: memory_utilization  
      threshold: '80'
      query: avg(memory_usage_percent)
  - type: cron
    metadata:
      timezone: UTC
      start: "0 9 * * 1-5"
      end: "0 17 * * 1-5"
      desiredReplicas: "3"
```

## Authentication & Security

### TriggerAuthentication

**Prometheus Authentication**:
```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: prometheus-auth
spec:
  secretTargetRef:
    - parameter: username
      name: prometheus-secret
      key: username
    - parameter: password
      name: prometheus-secret
      key: password
```

**Vault Integration**:
```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: vault-auth
spec:
  hashiCorpVault:
    address: https://vault.sbbh.cloud:8200
    authentication: kubernetes
    role: keda-operator
    mount: kubernetes
    secrets:
      - parameter: connection-string
        key: database-url
        path: keda/database-config
```

### ClusterTriggerAuthentication

**Cluster-Wide Authentication**:
```yaml
apiVersion: keda.sh/v1alpha1
kind: ClusterTriggerAuthentication
metadata:
  name: cluster-prometheus-auth
spec:
  secretTargetRef:
    - parameter: serverAddress
      name: prometheus-config
      key: server-url
      namespace: observability
```

## Monitoring & Observability

### KEDA Metrics

**Operator Metrics**:
- **Scaler Activity**: Active scalers and trigger evaluations
- **Scaling Events**: Scale up/down events and durations
- **Error Rates**: Failed metric retrievals and scaling errors
- **Resource Usage**: KEDA operator resource consumption

**Custom Metrics Exposure**:
```yaml
# ServiceMonitor for KEDA metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: keda-operator-metrics
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: keda-operator
  endpoints:
  - port: http-metrics
    path: /metrics
```

### Scaling Analytics

**Prometheus Queries for Scaling Analysis**:
```promql
# Scaling frequency per ScaledObject
rate(keda_scaledobject_triggers_total[5m])

# Average scaling time
histogram_quantile(0.95, rate(keda_scaledobject_scaling_duration_seconds_bucket[5m]))

# Active scaling triggers
keda_scaledobject_triggers_active

# Failed scaling attempts
rate(keda_scaledobject_errors_total[5m])
```

### Grafana Dashboards

**KEDA Overview Dashboard**:
- Active ScaledObjects and ScaledJobs
- Scaling event timeline
- Trigger evaluation success rates
- Resource utilization trends

**Application-Specific Dashboards**:
- VolSync scaling patterns
- Storage workload scaling correlation
- Batch job processing efficiency

## Best Practices

### Resource Management

**CPU and Memory Limits**:
```yaml
spec:
  scaleTargetRef:
    name: example-app
  advanced:
    restoreToOriginalReplicaCount: true
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
          - type: Percent
            value: 50
            periodSeconds: 60
        scaleUp:
          stabilizationWindowSeconds: 60
          policies:
          - type: Percent
            value: 100
            periodSeconds: 60
```

**Scaling Behavior Configuration**:
- **Scale Up**: Aggressive scaling for responsiveness
- **Scale Down**: Conservative scaling to prevent flapping
- **Stabilization Windows**: Prevent rapid scaling oscillations

### Trigger Design

**Metric Selection**:
- **Leading Indicators**: Queue depth, request rate trends
- **Lagging Indicators**: CPU, memory for safety nets
- **Business Metrics**: User-facing performance indicators

**Threshold Tuning**:
- **Conservative Start**: Begin with higher thresholds
- **Iterative Refinement**: Adjust based on observed behavior
- **Load Testing**: Validate scaling under artificial load

### Operational Considerations

**Deployment Coordination**:
```yaml
spec:
  scaleTargetRef:
    name: example-app
  advanced:
    scalingModifiers:
      formula: "ceil(current_replicas * 1.5)"
      target: "average"
      activationThreshold: 5
      metricType: "AverageValue"
```

**Rollback Safety**:
- **Original Replica Count**: Preserve pre-KEDA scaling state
- **Manual Override**: Ability to disable KEDA scaling
- **Circuit Breakers**: Prevent cascading scaling failures

## Troubleshooting

### Common Issues

**Admission Webhook Failures**:
```bash
# Check feature gate configuration
talosctl get machineconfig -n <control-plane-node> | grep feature-gates

# Verify webhook endpoints
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations
```

**Metrics Collection Problems**:
```bash
# Test Prometheus connectivity
kubectl exec -n keda-system deployment/keda-operator -- curl -f http://prometheus-operated.observability.svc.cluster.local:9090/api/v1/query?query=up

# Check trigger authentication
kubectl describe triggerauthentication -n <namespace>
```

**Scaling Delays**:
```bash
# Check HPA status
kubectl describe hpa keda-hpa-<scaledobject>

# Examine KEDA operator logs
kubectl logs -n keda-system deployment/keda-operator
```

### Debug Commands

**ScaledObject Status**:
```bash
# Check ScaledObject health
kubectl describe scaledobject <name>

# View trigger evaluation
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" | jq '.resources[] | select(.name | contains("example"))'
```

**Metrics Validation**:
```bash
# Test metric queries directly
kubectl exec -n observability deployment/prometheus-operated -- promtool query instant 'sum(example_metric)'

# Check custom metrics API
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1"
```

## Future Enhancements

### Short Term (1-3 months)
- **Multi-Cluster Scaling**: Cross-cluster workload distribution
- **Cost-Aware Scaling**: Scaling decisions based on resource costs
- **Advanced Triggers**: Custom webhook and event-based triggers
- **Scaling Policies**: Namespace-level scaling governance

### Medium Term (3-6 months)
- **Machine Learning Integration**: Predictive scaling based on historical patterns
- **Service Mesh Integration**: Scaling based on service mesh metrics
- **Edge Computing**: KEDA deployment for edge workloads
- **Disaster Recovery**: Scaling during failover scenarios

### Long Term (6+ months)
- **Federated Scaling**: Multi-cloud scaling coordination
- **Serverless Integration**: Knative and KEDA unified scaling
- **AI Workload Optimization**: Specialized scaling for ML/AI pipelines
- **Compliance Automation**: Scaling within regulatory constraints