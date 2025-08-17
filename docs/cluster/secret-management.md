# Secret Management

## Overview

The cluster uses HashiCorp Vault for centralized secret storage with External Secrets Operator for automatic synchronization to Kubernetes secrets.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Vault VPS     │◄──►│  External Secrets │◄──►│ Kubernetes      │
│  (vps.int.      │    │  Operator         │    │ Secrets         │
│   sbbh.cloud)   │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         ▲                        ▲                        ▲
         │                        │                        │
    TLS + CA                 Vault Token              Pod Consumption
```

## Vault Configuration

### Connection Details
- **URL**: `https://vps.int.sbbh.cloud:8200`
- **Engine**: KV Secrets Engine v2
- **Path**: `secret/`
- **Authentication**: Token-based
- **TLS**: Custom CA certificate

### Secret Organization
```
secret/
└── k8s/
    ├── github-deploy           # SSH key for GitOps
    ├── github-webhook-token    # Webhook authentication
    ├── cloudflare-api-token    # DNS challenge for certificates
    └── ...                     # Additional app secrets
```

## External Secrets Operator

### ClusterSecretStore Configuration

The `vault-backend` ClusterSecretStore is configured to connect to Vault:

```yaml
# k8s/apps/external-secrets/external-secrets/app/clustersecretstore.yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vps.int.sbbh.cloud:8200"
      path: "secret"
      version: "v2"
      auth:
        tokenSecretRef:
          name: "vault-token"
          key: "token"
          namespace: "kube-system"
      caProvider:
        type: Secret
        name: vault-ca-cert
        key: ca.crt
        namespace: "flux-system"
```

### Required Kubernetes Secrets

1. **Vault Token** (`kube-system/vault-token`):
   - Contains Vault authentication token
   - Created during bootstrap process

2. **Vault CA Certificate** (`flux-system/vault-ca-cert`):
   - Custom CA certificate for TLS verification
   - Downloaded from Vault server during bootstrap

## Workflow

### 1. Store Secret in Vault

```bash
# Example: Store application credentials
vault kv put secret/k8s/my-app \
  username=admin \
  password=secret123 \
  api-key=abc123xyz
```

### 2. Create ExternalSecret

```yaml
# k8s/apps/my-namespace/my-app/app/externalsecret.yaml
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: my-app-credentials
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
    - secretKey: password
      remoteRef:
        key: k8s/my-app
        property: password
```

### 3. Use Secret in Application

```yaml
# HelmRelease values or Pod spec
env:
  - name: USERNAME
    valueFrom:
      secretKeyRef:
        name: my-app-secret
        key: username
  - name: PASSWORD
    valueFrom:
      secretKeyRef:
        name: my-app-secret
        key: password
```

## Current Secrets

### GitOps Secrets

1. **GitHub Deploy Key** (`flux-system/github-deploy-key`):
   ```yaml
   apiVersion: external-secrets.io/v1
   kind: ExternalSecret
   metadata:
     name: github-deploy-key
     namespace: flux-system
   spec:
     data:
       - secretKey: identity
         remoteRef:
           key: k8s/github-deploy
           property: identity
       - secretKey: known_hosts
         remoteRef:
           key: k8s/github-deploy
           property: known_hosts
   ```

2. **GitHub Webhook Token** (`flux-system/github-webhook-token-secret`):
   ```yaml
   data:
     - secretKey: token
       remoteRef:
         key: k8s/github-webhook-token
         property: token
   ```

### Certificate Management

3. **Cloudflare API Token** (`cert-manager/cloudflare-issuer-secret`):
   ```yaml
   data:
     - secretKey: CLOUDFLARE_DNS_TOKEN
       remoteRef:
         key: k8s/cloudflare-api-token
         property: api-token
   ```

### Status Notifications

4. **GitHub Status Token** (multiple namespaces):
   - Used for Flux status notifications to GitHub
   - Synced to various namespaces for alerts

## Security Best Practices

### Vault Access Control

1. **Dedicated Service Account**:
   - External Secrets uses dedicated Vault token
   - Limited to KV secrets engine read access
   - Token stored securely in cluster

2. **Network Security**:
   - Vault accessible via Tailscale VPN
   - TLS encryption with custom CA
   - DNS resolution via OPNsense

### Kubernetes Security

1. **Namespace Isolation**:
   - Secrets created in target namespaces only
   - Cross-namespace access via ClusterSecretStore

2. **RBAC**:
   - External Secrets Operator has minimal required permissions
   - Secrets accessible only to authorized service accounts

3. **Secret Rotation**:
   - ExternalSecrets refresh every hour
   - Automatic rotation when Vault secrets change

## Troubleshooting

### Check External Secrets Status

```bash
# List all ExternalSecrets
kubectl get externalsecret -A

# Check specific ExternalSecret
kubectl describe externalsecret my-app-credentials -n my-namespace

# View External Secrets Operator logs
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

### Common Issues

1. **ClusterSecretStore Not Ready**:
   ```bash
   # Check ClusterSecretStore status
   kubectl get clustersecretstore vault-backend
   
   # Verify Vault connectivity
   kubectl exec -n external-secrets deployment/external-secrets -- \
     curl -k https://vps.int.sbbh.cloud:8200/v1/sys/health
   ```

2. **Secret Sync Failures**:
   ```bash
   # Check ExternalSecret events
   kubectl get events -n my-namespace --field-selector involvedObject.name=my-app-credentials
   
   # Verify Vault secret exists
   vault kv get secret/k8s/my-app
   ```

3. **Certificate Issues**:
   ```bash
   # Check Vault CA certificate
   kubectl get secret vault-ca-cert -n flux-system -o yaml
   
   # Test TLS connection
   openssl s_client -connect vps.int.sbbh.cloud:8200 -verify_return_error
   ```

### Recovery Procedures

1. **Recreate Vault Token**:
   ```bash
   # Generate new token in Vault
   vault token create -policy=external-secrets
   
   # Update Kubernetes secret
   kubectl create secret generic vault-token \
     --from-literal=token="$NEW_TOKEN" \
     --namespace=kube-system --dry-run=client -o yaml | \
     kubectl apply -f -
   ```

2. **Refresh Vault CA Certificate**:
   ```bash
   # Download new certificate
   task k8s:bootstrap:create-vault-ca-secret
   ```

## Vault Policies

### External Secrets Policy

```hcl
# external-secrets.hcl
path "secret/data/k8s/*" {
  capabilities = ["read"]
}

path "secret/metadata/k8s/*" {
  capabilities = ["read"]
}
```

### Application-Specific Policies

```hcl
# my-app.hcl
path "secret/data/k8s/my-app" {
  capabilities = ["read"]
}

path "secret/metadata/k8s/my-app" {
  capabilities = ["read"]
}
```

## Monitoring

### Metrics

External Secrets Operator exposes Prometheus metrics:
- `externalsecret_sync_calls_total`
- `externalsecret_sync_calls_error`
- `secretstore_connection_status`

### Alerts

Configure alerts for:
- ExternalSecret sync failures
- ClusterSecretStore connectivity issues
- Secret age and rotation status