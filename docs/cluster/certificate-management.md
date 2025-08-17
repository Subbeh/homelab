# Certificate Management

## Overview

The cluster uses cert-manager for automated TLS certificate provisioning with Let's Encrypt as the Certificate Authority and Cloudflare DNS for domain validation.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Let's Encrypt │◄──►│   cert-manager   │◄──►│  Gateway API    │
│     (ACME)      │    │                  │    │  TLS Termination│
└─────────────────┘    └──────────────────┘    └─────────────────┘
         ▲                        ▲                        ▲
         │                        │                        │
   DNS-01 Challenge         Cloudflare API            Certificate
   Domain Validation         DNS Records              Secret Storage
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Cloudflare    │    │ External Secrets │    │ Kubernetes      │
│   DNS Provider  │    │ Operator         │    │ TLS Secrets     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Components

### cert-manager
- **Namespace**: `cert-manager`
- **Version**: v1.17.2
- **Chart**: Official Jetstack cert-manager

### ClusterIssuer
- **Name**: `letsencrypt-production`
- **Type**: ACME with DNS-01 challenge
- **Domain**: `sbbh.cloud` (including wildcards)

### Certificate
- **Name**: `sbbh-cloud`
- **Namespace**: `kube-system` (for Gateway API)
- **Domains**: `sbbh.cloud`, `*.sbbh.cloud`

## Configuration

### ClusterIssuer Setup

```yaml
# k8s/apps/cert-manager/cert-manager/app/clusterissuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-production
      namespace: cert-manager
    solvers:
      - dns01:
          cloudflare:
            apiTokenSecretRef:
              name: cloudflare-issuer-secret
              key: CLOUDFLARE_DNS_TOKEN
              namespace: cert-manager
        selector:
          dnsZones: ["sbbh.cloud"]
```

### Wildcard Certificate

```yaml
# k8s/apps/kube-system/cilium/gateway/certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: sbbh-cloud
spec:
  secretName: sbbh-cloud-tls
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  commonName: sbbh.cloud
  dnsNames: 
    - "sbbh.cloud"
    - "*.sbbh.cloud"
```

### Cloudflare API Token

The Cloudflare API token is stored in Vault and synchronized via External Secrets:

```yaml
# k8s/apps/cert-manager/cert-manager/app/externalsecret.yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: cloudflare-issuer
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: vault-backend
  target:
    name: cloudflare-issuer-secret
    creationPolicy: Owner
  data:
    - secretKey: CLOUDFLARE_DNS_TOKEN
      remoteRef:
        key: k8s/cloudflare-api-token
        property: api-token
```

## DNS-01 Challenge Process

### How It Works

1. **Certificate Request**: Application requests certificate via Certificate resource
2. **ACME Order**: cert-manager creates ACME order with Let's Encrypt
3. **DNS Challenge**: Let's Encrypt provides DNS challenge token
4. **DNS Record Creation**: cert-manager creates TXT record via Cloudflare API
5. **Domain Validation**: Let's Encrypt validates domain ownership via DNS
6. **Certificate Issuance**: Let's Encrypt issues certificate
7. **Secret Storage**: cert-manager stores certificate in Kubernetes Secret

### DNS Record Example

During challenge, cert-manager creates:
```
_acme-challenge.sbbh.cloud. TXT "challenge-token-here"
```

## Gateway Integration

### TLS Termination

```yaml
# k8s/apps/kube-system/cilium/gateway/external.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: external
spec:
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.sbbh.cloud"
      tls:
        certificateRefs:
          - kind: Secret
            name: sbbh-cloud-tls  # Certificate from cert-manager
```

### HTTPRoute with TLS

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
spec:
  hostnames: ["my-app.sbbh.cloud"]
  parentRefs:
    - name: external
      namespace: kube-system
      sectionName: https
  rules:
    - backendRefs:
        - name: my-app-service
          port: 80
```

## Certificate Lifecycle

### Automatic Renewal

- **Default Renewal**: 30 days before expiration
- **Let's Encrypt Validity**: 90 days
- **Effective Renewal**: Every 60 days
- **Renewal Check**: Every hour

### Certificate Status

```bash
# Check certificate status
kubectl get certificate -A

# Detailed certificate information
kubectl describe certificate sbbh-cloud -n kube-system

# Check certificate expiration
kubectl get secret sbbh-cloud-tls -n kube-system -o yaml | \
  grep tls.crt | awk '{print $2}' | base64 -d | \
  openssl x509 -text -noout | grep "Not After"
```

## Monitoring

### Certificate Metrics

cert-manager exposes Prometheus metrics:
- `certmanager_certificate_expiration_timestamp_seconds`
- `certmanager_certificate_ready_status`
- `certmanager_acme_client_request_count`

### Alerts

Recommended alerts:
```yaml
groups:
  - name: certificates
    rules:
      - alert: CertificateExpiringSoon
        expr: (certmanager_certificate_expiration_timestamp_seconds - time()) / 86400 < 7
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "Certificate {{ $labels.name }} expires in less than 7 days"

      - alert: CertificateNotReady
        expr: certmanager_certificate_ready_status == 0
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "Certificate {{ $labels.name }} is not ready"
```

## Adding New Certificates

### For Applications

#### Option 1: Use Existing Wildcard Certificate

Reference the existing wildcard certificate:
```yaml
# In your Gateway or Ingress
tls:
  certificateRefs:
    - kind: Secret
      name: sbbh-cloud-tls
      namespace: kube-system  # Reference existing cert
```

#### Option 2: Create Application-Specific Certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-app-cert
  namespace: my-namespace
spec:
  secretName: my-app-tls
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  dnsNames:
    - my-app.sbbh.cloud
```

### For Different Domains

1. **Add Domain to ClusterIssuer**:
   ```yaml
   selector:
     dnsZones: ["sbbh.cloud", "example.com"]
   ```

2. **Create Certificate**:
   ```yaml
   apiVersion: cert-manager.io/v1
   kind: Certificate
   metadata:
     name: example-com-cert
   spec:
     dnsNames:
       - example.com
       - "*.example.com"
   ```

## Troubleshooting

### Common Issues

1. **Certificate Stuck in Pending**:
   ```bash
   # Check certificate status
   kubectl describe certificate sbbh-cloud -n kube-system
   
   # Check certificate request
   kubectl get certificaterequest -n kube-system
   kubectl describe certificaterequest <name> -n kube-system
   ```

2. **DNS Challenge Failures**:
   ```bash
   # Check ACME order
   kubectl get order -n kube-system
   kubectl describe order <name> -n kube-system
   
   # Check challenge
   kubectl get challenge -n kube-system
   kubectl describe challenge <name> -n kube-system
   ```

3. **Cloudflare API Issues**:
   ```bash
   # Check External Secret
   kubectl get externalsecret cloudflare-issuer -n cert-manager
   
   # Verify secret content
   kubectl get secret cloudflare-issuer-secret -n cert-manager -o yaml
   
   # Test Cloudflare API
   curl -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "Authorization: Bearer $CLOUDFLARE_TOKEN"
   ```

### Manual Certificate Renewal

```bash
# Force certificate renewal
kubectl annotate certificate sbbh-cloud -n kube-system \
  cert-manager.io/force-renewal="$(date +%s)"

# Delete certificate to recreate
kubectl delete certificate sbbh-cloud -n kube-system
# Certificate will be automatically recreated due to Gateway reference
```

### DNS Propagation Testing

```bash
# Check DNS propagation
dig _acme-challenge.sbbh.cloud TXT

# Global DNS propagation check
curl "https://www.whatsmydns.net/api/details?server=world&type=TXT&query=_acme-challenge.sbbh.cloud"
```

## Security Considerations

### API Token Permissions

Cloudflare API token requires:
- **Zone Resources**: `Zone:Zone:Read`, `Zone:DNS:Edit`
- **Specific Zones**: `sbbh.cloud`
- **IP Filtering**: Optional (recommended for production)

### Secret Management

1. **Vault Storage**: API token stored in Vault
2. **External Secrets**: Automatic synchronization
3. **Namespace Isolation**: Secrets scoped to cert-manager namespace
4. **Token Rotation**: Periodic rotation recommended

### Certificate Storage

1. **Kubernetes Secrets**: TLS certificates stored as secrets
2. **Access Control**: RBAC controls secret access
3. **Encryption**: Secrets encrypted at rest (Talos default)
4. **Backup**: Consider backing up certificate secrets

## Cloudflare Token Setup

### Creating API Token

1. **Login to Cloudflare Dashboard**
2. **Go to Profile → API Tokens**
3. **Create Token with**:
   - **Template**: Custom token
   - **Permissions**: 
     - Zone:Zone:Read
     - Zone:DNS:Edit
   - **Zone Resources**: Include specific zones (`sbbh.cloud`)

### Storing in Vault

```bash
# Store token in Vault
vault kv put secret/k8s/cloudflare-api-token api-token="your-token-here"

# Verify storage
vault kv get secret/k8s/cloudflare-api-token
```

## Best Practices

### Certificate Management

1. **Use Wildcard Certificates**: Reduce API calls and complexity
2. **Monitor Expiration**: Set up alerts for certificate expiration
3. **Test Renewals**: Regularly test certificate renewal process
4. **Backup Certificates**: Keep secure backups of important certificates

### DNS Management

1. **Dedicated API Tokens**: Use specific tokens for cert-manager
2. **Minimal Permissions**: Grant only required permissions
3. **Token Rotation**: Rotate API tokens regularly
4. **DNS Monitoring**: Monitor DNS record changes

### Security

1. **Secret Rotation**: Regularly rotate Cloudflare API tokens
2. **Access Control**: Limit access to certificate secrets
3. **Audit Logs**: Monitor certificate requests and renewals
4. **Network Policies**: Restrict cert-manager network access