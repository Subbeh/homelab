# GitOps Workflow

## Overview

The cluster uses Flux v2 for GitOps-based continuous deployment. All cluster configuration is stored in the GitHub repository and automatically synchronized.

## Bootstrap Process

### Initial Setup

1. **Run Bootstrap Task**:
   ```bash
   task k8s:bootstrap:init
   ```

2. **Bootstrap Tasks Executed**:
   - Create namespaces (cert-manager, external-secrets, flux-system, network)
   - Generate GitHub deploy key
   - Store secrets in Vault
   - Deploy Flux via Helmfile
   - Configure External Secrets integration

### Manual Bootstrap Steps

If running individual tasks:

```bash
# 1. Create namespaces
task k8s:bootstrap:create-namespaces

# 2. Generate and store GitHub deploy key
task k8s:bootstrap:generate-deploy-key
task k8s:bootstrap:add-github-deploy-key
task k8s:bootstrap:store-deploy-key

# 3. Generate and store webhook token
task k8s:bootstrap:generate-webhook-token
task k8s:bootstrap:store-webhook-token

# 4. Store Cloudflare API token
task k8s:bootstrap:store-cf-api-token

# 5. Create Vault secrets in cluster
task k8s:bootstrap:create-vault-token-secret
task k8s:bootstrap:create-vault-ca-secret

# 6. Deploy core components
task k8s:bootstrap:helmfile

# 7. Apply External Secrets configuration
task k8s:bootstrap:apply-external-secrets-config
```

## Flux Components

### Core Components

1. **Flux Operator** (`flux-system/flux-operator`)
   - Manages Flux lifecycle
   - Handles Flux instance configuration

2. **Flux Instance** (`flux-system/flux-instance`)
   - GitOps reconciliation engine
   - GitHub webhook receiver

3. **Source Controller**
   - Git repository synchronization
   - OCI repository management

4. **Kustomize Controller**
   - Kubernetes manifest application
   - Kustomization processing

## Repository Structure

### Application Organization

```
k8s/
├── apps/
│   ├── cert-manager/
│   │   ├── kustomization.yaml          # Namespace-level resources
│   │   └── cert-manager/
│   │       ├── ks.yaml                 # Flux Kustomization
│   │       └── app/
│   │           ├── helmrelease.yaml    # Helm deployment
│   │           ├── externalsecret.yaml # Secret management
│   │           └── clusterissuer.yaml  # Certificate issuer
│   └── kube-system/
│       ├── kustomization.yaml          # Namespace-level resources
│       ├── cilium/
│       ├── coredns/
│       └── spegel/
├── components/
│   └── common/
│       ├── alerts/                     # Flux notifications
│       └── repos/                      # Helm repositories
└── flux/
    └── cluster/
        ├── ks.yaml                     # Main cluster kustomization
        ├── cluster-apps.yaml           # App orchestration
        └── github-deploy-key.yaml      # Git authentication
```

### Kustomization Hierarchy

1. **Root Kustomization** (`flux-system`)
   - Applies `k8s/flux/cluster/ks.yaml`
   - Bootstraps the GitOps system

2. **Cluster Apps** (`cluster-apps`)
   - Applies all applications in `k8s/apps/`
   - Uses namespace-level kustomizations

3. **App Kustomizations** (per application)
   - Individual app lifecycle management
   - Health checks and dependencies

## Adding Applications

### 1. Create Application Structure

```bash
mkdir -p k8s/apps/my-namespace/my-app/{app,ks.yaml}
```

### 2. Create Flux Kustomization (`ks.yaml`)

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app
  namespace: my-namespace
spec:
  interval: 1h
  path: ./k8s/apps/my-namespace/my-app/app
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  targetNamespace: my-namespace
  timeout: 5m
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2
      kind: HelmRelease
      name: my-app
      namespace: my-namespace
```

### 3. Create Application Resources

```bash
# HelmRelease example
cat > k8s/apps/my-namespace/my-app/app/helmrelease.yaml << EOF
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-app
spec:
  interval: 1h
  chart:
    spec:
      chart: my-chart
      version: "1.0.0"
      sourceRef:
        kind: HelmRepository
        name: my-repo
        namespace: flux-system
  values:
    # App configuration
EOF
```

### 4. Update Namespace Kustomization

```yaml
# k8s/apps/my-namespace/kustomization.yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: my-namespace
components:
  - ../../components/common
resources:
  - ./my-app/ks.yaml
```

### 5. Commit and Push

```bash
git add k8s/apps/my-namespace/
git commit -m "feat: add my-app deployment"
git push
```

## Secret Management Integration

### External Secrets Workflow

1. **Store Secret in Vault**:
   ```bash
   vault kv put secret/k8s/my-app username=admin password=secret123
   ```

2. **Create ExternalSecret**:
   ```yaml
   ---
   apiVersion: external-secrets.io/v1
   kind: ExternalSecret
   metadata:
     name: my-app-secret
   spec:
     secretStoreRef:
       kind: ClusterSecretStore
       name: vault-backend
     target:
       name: my-app-secret
       creationPolicy: Owner
     data:
       - secretKey: username
         remoteRef:
           key: k8s/my-app
           property: username
   ```

## Monitoring GitOps

### Check Flux Status

```bash
# All Kustomizations
kubectl get kustomization -A

# Specific application
kubectl describe kustomization my-app -n my-namespace

# Flux events
kubectl get events -n flux-system --sort-by='.lastTimestamp'
```

### Common Commands

```bash
# Force reconciliation
kubectl annotate gitrepository flux-system -n flux-system \
  reconcile.fluxcd.io/requestedAt="$(date +%Y-%m-%dT%H:%M:%SZ)" --overwrite

# Check webhook status
kubectl get receiver -A

# View application logs
kubectl logs -n flux-system -l app=flux-instance
```

## Webhook Configuration

### GitHub Webhook URL
```
https://flux-webhook.sbbh.cloud/hook/dda775ef2183f2a573e6d6d87c0a243810467e6b8efadafbebb4cc2c253d2fb4
```

### Webhook Events
- **push** to main branch
- **pull_request** merge to main
- Automatic deployment within 30 seconds

## Troubleshooting

### Common Issues

1. **Kustomization Fails**
   - Check resource syntax: `kubectl get kustomization <name> -n <namespace> -o yaml`
   - Verify dependencies: Ensure required resources exist

2. **GitHub Authentication**
   - Check deploy key: `kubectl get secret github-deploy-key -n flux-system`
   - Verify SSH key in GitHub repository settings

3. **Secret Sync Issues**
   - Check Vault connectivity: `kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets`
   - Verify ClusterSecretStore: `kubectl get clustersecretstore vault-backend`

### Recovery Procedures

1. **Re-bootstrap Flux**:
   ```bash
   task k8s:bootstrap:init
   ```

2. **Regenerate Deploy Key**:
   ```bash
   task k8s:bootstrap:generate-deploy-key
   task k8s:bootstrap:add-github-deploy-key
   task k8s:bootstrap:store-deploy-key
   ```