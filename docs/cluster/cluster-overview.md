# Cluster Overview

## Architecture

This homelab runs a multi-node Kubernetes cluster using Talos Linux with GitOps-based management through Flux.

## Infrastructure Components

### Core Platform

- **Talos Linux**: Immutable Kubernetes OS (v1.10.4)
- **Kubernetes**: v1.33.2 multi-control-plane cluster
- **Nodes**:
    - `k8s-nuc` (10.11.80.11) - Control Plane + Worker
    - `k8s-opti-01` (10.11.80.12) - Control Plane + Worker
    - `k8s-opti-02` (10.11.80.13) - Control Plane + Worker

### Networking

- **CNI**: Cilium with eBPF
- **LoadBalancer**: Cilium L2 announcements
- **Gateway API**: Cilium Gateway implementation
- **DNS**: k8s-gateway for service discovery, CoreDNS for cluster DNS
- **External DNS**: Removed (replaced with k8s-gateway)

### Storage

- **Registry Mirror**: Spegel for container image caching
- **Distributed Storage**: Rook-Ceph cluster with 3 OSDs
- **Backup & Replication**: VolSync with Restic backend
- **Autoscaling**: KEDA for HPA and workload scaling
- **NFS Storage**: External NAS integration for persistent volumes

## Network Topology

```
Internet
    │
    ▼
OPNsense Router/Firewall (10.11.80.1)
    │
    ▼
Kubernetes Network (10.11.80.0/24)
    │
    ├── k8s-nuc (10.11.80.11) - Control Plane + Worker
    ├── k8s-opti-01 (10.11.80.12) - Control Plane + Worker
    ├── k8s-opti-02 (10.11.80.13) - Control Plane + Worker
    ├── API VIP (10.11.80.100) - Kubernetes API
    ├── External Gateway (10.11.80.80) - Public ingress
    └── Internal Gateway (10.11.80.81) - Internal ingress
    │
    ▼
Pod Network (10.42.0.0/16)
Service Network (10.43.0.0/16)
```

## Application Architecture

### GitOps Management

- **Flux System**: GitOps orchestration
- **Source**: GitHub repository with SSH authentication
- **Webhook**: Automated deployments via GitHub webhooks

### Secret Management

- **Vault**: HashiCorp Vault on external VPS
- **External Secrets Operator**: Kubernetes secret synchronization
- **TLS**: Vault CA certificate for secure communication

### Certificate Management

- **cert-manager**: Automated TLS certificate provisioning
- **Let's Encrypt**: ACME provider with DNS-01 challenges
- **Cloudflare**: DNS provider for domain validation

## Security Model

### Network Security

- **Tailscale**: VPN connectivity to external services
- **OPNsense**: Firewall and DNS overrides
- **Cilium Network Policies**: Pod-to-pod communication control

### Secret Security

- **Vault Transit**: Encrypted secret storage
- **SSH Keys**: Automated rotation for GitOps
- **TLS Everywhere**: Encrypted communication

### Access Control

- **Talos API**: Secure node management
- **Kubernetes RBAC**: Role-based access control
- **Service Accounts**: Minimal privilege principles

## Monitoring & Observability

### Application Monitoring

- **Prometheus**: Core metrics collection and alerting engine
- **Alertmanager**: Alert routing and notification management
- **Grafana**: Visualization dashboards and analytics
- **Loki**: Log aggregation and query engine
- **Service Monitors**: Automatic metrics collection for applications

### Infrastructure Monitoring

- **Node Exporter**: System metrics from all nodes including OPNsense
- **Kube-State-Metrics**: Kubernetes object state metrics
- **Ceph Monitoring**: Storage cluster health and performance
- **Network Metrics**: Cilium connectivity and performance
- **Custom Alerts**: CPU overcommit, OOM kills, ZFS state, and Docker rate limits

## Deployment Strategy

### GitOps Workflow

1. **Code Changes**: Push to GitHub repository
2. **Webhook Trigger**: Flux receives webhook notification
3. **Sync**: Flux pulls latest configuration
4. **Apply**: Kubernetes resources updated automatically
5. **Validation**: Health checks and status monitoring

### Application Structure

```
k8s/
├── apps/                    # Application deployments
│   ├── cert-manager/       # Certificate management
│   ├── external-secrets/   # Secret synchronization
│   ├── flux-system/        # GitOps components (operator + instance)
│   ├── kube-system/        # Core cluster services (cilium, coredns, spegel, k8s-gateway)
│   ├── observability/      # Monitoring stack (prometheus, grafana, loki, alertmanager)
│   ├── rook-ceph/          # Distributed storage cluster
│   ├── volsync/            # Backup and replication system
│   └── keda/              # Kubernetes Event-driven Autoscaling
├── components/             # Shared configurations
└── flux/                   # Flux bootstrap configuration
```

## Scalability Considerations

### Current Capabilities

- Distributed storage with Rook-Ceph (3 OSDs across nodes)
- Full monitoring stack with Prometheus, Grafana, Loki, and Alertmanager
- Automated backup and replication with VolSync
- Event-driven autoscaling with KEDA
- Multi-control-plane HA cluster

### Current Limitations

- Single availability zone deployment
- Limited network storage integration (NFS only)
- Manual disaster recovery procedures

### Future Expansion Options

- Multi-zone deployment for enhanced availability
- Additional storage backends (OpenEBS for local storage)
- Enhanced backup strategies with cross-cluster replication
- Application-specific monitoring and alerting rules
- Service mesh integration for advanced networking
