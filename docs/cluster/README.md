# Homelab Kubernetes Cluster Documentation

This directory contains comprehensive documentation for the homelab Kubernetes cluster running on Talos Linux with Flux GitOps.

## 📚 Documentation Structure

- **[Cluster Overview](./cluster-overview.md)** - High-level architecture and components
- **[GitOps Workflow](./gitops-workflow.md)** - Flux-based deployment and management
- **[Secret Management](./secret-management.md)** - Vault integration and External Secrets
- **[Network Configuration](./network-config.md)** - Cilium CNI, LoadBalancer, and Gateway API
- **[Certificate Management](./certificate-management.md)** - cert-manager and Let's Encrypt automation
- **[Troubleshooting](./troubleshooting.md)** - Common issues and solutions
- **[Maintenance](./maintenance.md)** - Operational procedures and updates

## 🚀 Quick Start

1. **Bootstrap Process**: See [GitOps Workflow](./gitops-workflow.md#bootstrap-process)
2. **Adding Applications**: See [GitOps Workflow](./gitops-workflow.md#adding-applications)
3. **Managing Secrets**: See [Secret Management](./secret-management.md#workflow)

## 🏗️ Infrastructure Stack

| Component | Purpose | Status |
|-----------|---------|--------|
| **Talos Linux** | Immutable Kubernetes OS | ✅ Operational |
| **Flux** | GitOps deployment | ✅ Operational |
| **Cilium** | Network CNI + LoadBalancer | ✅ Operational |
| **cert-manager** | TLS certificate automation | ✅ Operational |
| **External Secrets** | Vault integration | ✅ Operational |
| **Gateway API** | Ingress with TLS termination | ✅ Operational |
| **k8s_gateway** | Internal DNS resolution | ✅ Operational |

## 📊 Network Information

- **Cluster Network**: `10.11.80.0/24`
- **Pod Network**: `10.42.0.0/16`
- **Service Network**: `10.43.0.0/16`
- **External Gateway**: `10.11.80.80` (public access)
- **Internal Gateway**: `10.11.80.81` (internal access)
- **k8s_gateway**: `10.11.80.82` (DNS resolution)

## 🔐 Security Features

- ✅ **Vault-based secret management**
- ✅ **Automated TLS certificates**
- ✅ **SSH key rotation for GitOps**
- ✅ **Network policies via Cilium**
- ✅ **Split DNS with k8s_gateway**
- ✅ **Internal/External gateway separation**

## 📞 Support

For issues and questions:
1. Check the [Troubleshooting Guide](./troubleshooting.md)
2. Review component logs: `kubectl logs -n <namespace> <pod>`
3. Check Flux status: `kubectl get kustomization -A`