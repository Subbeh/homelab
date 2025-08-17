# Monitoring & Observability

## Overview

The cluster implements a comprehensive monitoring and observability stack based on the Prometheus ecosystem, providing metrics collection, alerting, log aggregation, and visualization capabilities across all infrastructure and application layers.

## Core Components

### Prometheus Stack (kube-prometheus-stack)

**Purpose**: Centralized metrics collection, storage, and alerting engine for the entire cluster.

**Architecture**:
- **Prometheus Server**: Core metrics database with 14-day retention and 50GB storage
- **Prometheus Operator**: Kubernetes-native management of monitoring components
- **Custom Image**: prompp/prompp:2.53.2-0.3.3 for enhanced compatibility
- **Security Context**: Non-root execution (UID 64535) for security compliance

**Resource Configuration**:
```yaml
resources:
  requests:
    cpu: 100m
  limits:
    memory: 2000Mi
storageSpec:
  volumeClaimTemplate:
    spec:
      storageClassName: ceph-block
      resources:
        requests:
          storage: 50Gi
```

**Selectors**: All monitor types enabled for comprehensive discovery:
- PodMonitors, ProbeMonitors, Rules, ScrapeConfigs, ServiceMonitors

### Alertmanager

**Purpose**: Alert routing, grouping, and notification management with external integrations.

**Configuration**:
- **External URL**: https://alertmanager.sbbh.cloud
- **Storage**: 1Gi Ceph block storage for persistent configuration
- **Secret Integration**: External Secrets Operator with Vault backend for credentials

**Notification Channels**:
- Pushover integration for mobile notifications
- Email notifications via SMTP relay
- Webhook integrations for external systems

**Secret Template**:
```yaml
target:
  template:
    data:
      pushover_token: "{{ .pushover_token }}"
      pushover_user_key: "{{ .pushover_user_key }}"
```

### Grafana

**Purpose**: Data visualization, dashboard provisioning, and analytics interface.

**Key Features**:
- **External URL**: https://grafana.sbbh.cloud
- **Anonymous Access**: Read-only viewer access for public dashboards
- **Data Sources**: Prometheus, Loki, Alertmanager integration
- **Dashboard Provisioning**: Automated dashboard deployment via GitOps

**Authentication**:
- Admin credentials via External Secrets integration
- Anonymous viewers for operational dashboards
- Browser locale support for international users

**Dashboard Collection**:
- **Infrastructure**: Node Exporter Full (1860), Kubernetes Views (15757-15760)
- **Storage**: Ceph Cluster (2842), Ceph OSDs (5336), Ceph Pools (5342)
- **Applications**: VolSync (21356), Cert-manager (20842), Prometheus (19105)
- **Network**: pfSense FreeBSD (7179) for OPNsense monitoring

### Loki

**Purpose**: Log aggregation, parsing, and querying for centralized logging.

**Integration**:
- **URL**: http://loki-headless.observability.svc.cluster.local:3100
- **Max Lines**: 250 for query optimization
- **Grafana Integration**: Native log exploration and correlation

**Log Sources**:
- Container logs via Promtail or similar agents
- Application logs with structured formatting
- System logs from Talos nodes

### Node Exporter

**Purpose**: System-level metrics collection from all cluster nodes and infrastructure.

**Deployment**:
- **DaemonSet**: Runs on every Kubernetes node
- **External Targets**: OPNsense firewall via ScrapeConfig
- **Relabeling**: Instance identification and job assignment

**OPNsense Integration**:
```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: node-exporter
spec:
  staticConfigs:
    - targets:
        - 10.11.80.1:9100
  relabelings:
    - action: replace
      sourceLabels: [__address__]
      regex: "10.11.80.1:9100"
      targetLabel: instance
      replacement: opnsense
```

**Network Configuration**:
- **Firewall Rule**: K8S → OPNsense port 9100 access
- **OPNsense Plugin**: os-node_exporter for system metrics
- **Network Path**: K8S VLAN (10.11.80.0/24) to OPNsense interface (10.11.80.1)

### Kube-State-Metrics

**Purpose**: Kubernetes object state metrics for cluster health monitoring.

**Configuration**:
- **Metric Labels**: Comprehensive allowlist for pods, deployments, PVCs
- **Node Labeling**: Kubernetes node identification for pod placement
- **Resource Monitoring**: CPU, memory, storage requests and limits

## Service Discovery & Targets

### Automatic Discovery

**ServiceMonitors**: Automatic service endpoint discovery based on labels
**PodMonitors**: Pod-level metrics collection for applications
**ProbeMonitors**: Blackbox monitoring for external endpoints

### Static Targets

**External Infrastructure**:
- OPNsense firewall (10.11.80.1:9100)
- External services via Tailscale VPN
- VPS monitoring endpoints

### Custom ScrapeConfigs

**Node Exporter External**:
- OPNsense system metrics
- Network device monitoring
- Infrastructure health checks

## Alerting Strategy

### Built-in Alert Rules

**Resource Alerts**:
```yaml
# CPU Overcommit Detection
- alert: KubeCPUOvercommit
  expr: sum(kube_pod_container_resource_requests{resource="cpu"}) / sum(kube_node_status_allocatable{resource="cpu"}) > 1

# OOM Kill Detection  
- alert: OomKilled
  expr: (kube_pod_container_status_restarts_total - kube_pod_container_status_restarts_total offset 10m >= 1) and ignoring (reason) min_over_time(kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}[10m]) == 1
```

**Storage Alerts**:
```yaml
# ZFS Pool State Monitoring
- alert: ZfsUnexpectedPoolState
  expr: node_zfs_zpool_state{state!="online"} > 0
  labels:
    severity: critical
```

**External Service Alerts**:
```yaml
# Docker Hub Rate Limiting
- alert: DockerhubRateLimitRisk
  expr: count(time() - container_last_seen{image=~"(docker.io).*",container!=""} < 30) > 100
  labels:
    severity: critical
```

### Alert Routing

**Severity Levels**:
- **Critical**: Immediate notification (Pushover + Email)
- **Warning**: Batched notifications during business hours
- **Info**: Dashboard visibility only

**Grouping Strategy**:
- By cluster and namespace for application alerts
- By node for infrastructure alerts
- By severity for notification prioritization

## Network Monitoring

### OPNsense Integration

**Firewall Metrics**:
- Interface statistics and throughput
- Connection state tracking
- Firewall rule hit counters
- System resource utilization

**Dashboard Configuration**:
- pfSense FreeBSD dashboard (GrafanaID: 7179)
- Custom variables for interface selection
- Network traffic visualization
- Security event correlation

**Access Configuration**:
```yaml
# Ansible firewall rule
allow_k8s_node_exporter:
  interface: K8SGroup
  protocol: TCP
  source: __K8SGroup_network
  destination: "{{ aliases.host_opnsense_k8s.content }}"
  destination_port: 9100
  description: Allow K8S to OPNsense Node Exporter
```

### Cilium Network Monitoring

**CNI Metrics**:
- Pod-to-pod connectivity
- Network policy enforcement
- Load balancer performance
- eBPF program statistics

**Service Mesh Observability**:
- Traffic flow visualization
- Security policy compliance
- Performance bottleneck identification

## Storage Monitoring

### Ceph Cluster Monitoring

**Health Metrics**:
- Cluster health status (HEALTH_OK/WARN/ERR)
- OSD status and utilization
- Monitor quorum status
- Manager module health

**Performance Metrics**:
- Read/write IOPS and throughput
- Latency percentiles
- Recovery and rebalancing status
- Capacity utilization trends

**Dashboard Coverage**:
- Ceph Cluster overview with health summary
- Per-OSD performance and utilization
- Pool-level statistics and quotas

### VolSync Backup Monitoring

**Backup Metrics**:
- Job success and failure rates
- Backup duration and size trends
- Repository health and capacity
- Recovery point objectives (RPO)

**Alert Scenarios**:
- Backup job failures
- Repository connectivity issues
- Retention policy violations
- Cross-cluster replication lag

## Application Monitoring

### GitOps Monitoring

**Flux System Metrics**:
- Source controller synchronization
- Helm controller deployment status
- Kustomize controller reconciliation
- Webhook receiver activity

**Git Repository Health**:
- Commit synchronization lag
- Authentication failures
- Source availability monitoring

### Certificate Monitoring

**cert-manager Metrics**:
- Certificate expiration tracking
- ACME challenge success rates
- Issuer health and quota usage
- Renewal automation status

### External Secrets Monitoring

**Secret Synchronization**:
- Vault connectivity status
- Secret refresh success rates
- Authentication token health
- Drift detection and remediation

## Performance Optimization

### Metrics Retention

**Prometheus Configuration**:
- **Retention Period**: 14 days for detailed metrics
- **Retention Size**: 50GB maximum storage usage
- **Compaction**: Automatic time-series compaction
- **Remote Write**: Optional long-term storage integration

### Query Performance

**Label Strategy**:
- Consistent labeling across all metrics
- Node identification for cross-correlation
- Namespace and application grouping
- Instance relabeling for clarity

**Recording Rules**:
- Pre-computed aggregations for dashboards
- Resource utilization summaries
- SLA calculation automation

### Resource Management

**Component Sizing**:
- Prometheus: 100m CPU request, 2000Mi memory limit
- Grafana: Standard resource allocation with persistence disabled
- Alertmanager: Minimal resources with persistent storage

## Security & Compliance

### Authentication & Authorization

**Grafana Access Control**:
- Admin access via External Secrets
- Anonymous viewer permissions
- Dashboard-level access control

**Prometheus Security**:
- ServiceAccount-based access
- Network policy isolation
- TLS encryption for external endpoints

### Data Protection

**Sensitive Data Handling**:
- Credential masking in logs and metrics
- Secret rotation automation
- Audit trail maintenance

**Network Security**:
- Firewall rules for metric collection
- VPN connectivity for external targets
- TLS verification for external endpoints

## Operational Procedures

### Dashboard Management

**GitOps Workflow**:
1. Dashboard configuration in Git repository
2. Flux synchronization to cluster
3. Grafana automatic provisioning
4. Version control and rollback capabilities

**Dashboard Categories**:
- **Infrastructure**: Node, network, storage health
- **Platform**: Kubernetes cluster status
- **Applications**: Service-specific monitoring
- **Security**: Compliance and audit dashboards

### Alert Management

**Alert Lifecycle**:
1. **Detection**: Prometheus rule evaluation
2. **Routing**: Alertmanager group and route assignment
3. **Notification**: External system integration
4. **Acknowledgment**: Manual or automated response
5. **Resolution**: Root cause remediation

**Runbook Integration**:
- Alert annotations with troubleshooting links
- Automated remediation for known issues
- Escalation procedures for critical alerts

### Troubleshooting Workflows

**Common Issues**:

**Target Discovery Problems**:
```bash
# Check Prometheus targets
kubectl port-forward -n observability svc/prometheus-operated 9090:9090
# Access http://localhost:9090/targets
```

**Dashboard Data Issues**:
```bash
# Verify data source connectivity
kubectl exec -n observability deployment/grafana -- curl -f http://prometheus-operated:9090/api/v1/query?query=up
```

**Alert Delivery Problems**:
```bash
# Check Alertmanager configuration
kubectl logs -n observability deployment/alertmanager-operated
```

## Future Enhancements

### Short Term (1-3 months)
- **Distributed Tracing**: Jaeger integration for request tracing
- **Log Analysis**: Enhanced log parsing and alerting rules
- **Custom Metrics**: Application-specific SLI/SLO monitoring
- **Mobile Dashboards**: Responsive design for mobile operations

### Medium Term (3-6 months)
- **Multi-Cluster Monitoring**: Centralized observability across environments
- **AI/ML Integration**: Anomaly detection and predictive alerting
- **Compliance Dashboards**: Security and audit reporting
- **Performance Baselines**: Automated capacity planning

### Long Term (6+ months)
- **Edge Monitoring**: Remote site observability
- **Cost Optimization**: Resource usage and billing analytics
- **Chaos Engineering**: Monitoring during fault injection
- **Event Correlation**: Cross-system incident analysis