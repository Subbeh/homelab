# Network Configuration

## Overview

The cluster uses Cilium as the Container Network Interface (CNI) with advanced features including LoadBalancer services, Gateway API, and L2 announcements.

## Network Topology

### IP Address Allocation

```
┌─────────────────────────────────────────┐
│           Physical Network              │
│         10.11.80.0/24                   │
├─────────────────────────────────────────┤
│ OPNsense Router     │ 10.11.80.1        │
│ k8s-nuc (node)      │ 10.11.80.11       │
│ k8s-opti-01 (node)  │ 10.11.80.12       │
│ k8s-opti-02 (node)  │ 10.11.80.13       │
│ Kubernetes API VIP  │ 10.11.80.100      │
│ External Gateway    │ 10.11.80.80       │
│ Internal Gateway    │ 10.11.80.81       │
│ k8s_gateway         │ 10.11.80.82       │
│ LoadBalancer Pool   │ 10.11.80.0/24     │
└─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────┐
│         Kubernetes Networks             │
├─────────────────────────────────────────┤
│ Pod Network         │ 10.42.0.0/16      │
│ Service Network     │ 10.43.0.0/16      │
│ CoreDNS Service     │ 10.43.0.10        │
└─────────────────────────────────────────┘
```

### Network Components

1. **Cilium CNI**

    - eBPF-based networking
    - Native routing mode
    - L2 announcements for LoadBalancer services

2. **CoreDNS**

    - Cluster DNS resolution
    - Custom configuration for homelab domains

3. **Gateway API**

    - External and internal ingress gateways
    - TLS termination with cert-manager

4. **k8s_gateway**
    - Internal DNS resolution for Gateway API routes
    - Split DNS integration with OPNsense

## Cilium Configuration

### Core Features

```yaml
# k8s/apps/kube-system/cilium/app/helm/values.yaml
autoDirectNodeRoutes: true
bpf:
    masquerade: true
    hostLegacyRouting: true
    vlanBypass: [0]

ipam:
    mode: kubernetes
ipv4NativeRoutingCIDR: "10.42.0.0/16"

kubeProxyReplacement: true
routingMode: native

l2announcements:
    enabled: true
loadBalancer:
    algorithm: maglev
```

### Gateway API Support

```yaml
gatewayAPI:
    enabled: true
    enableAlpn: true
    enableAppProtocol: true

hubble:
    enabled: true
    metrics:
        enabled:
            - dns:query
            - drop
            - tcp
            - flow
            - port-distribution
            - icmp
            - http
```

## LoadBalancer Configuration

### IP Pool

```yaml
# k8s/apps/kube-system/cilium/app/networks.yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumLoadBalancerIPPool
metadata:
    name: pool
spec:
    allowFirstLastIPs: "No"
    blocks:
        - cidr: 10.11.80.0/24
```

### L2 Announcements

```yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
    name: l2-policy
spec:
    loadBalancerIPs: true
    interfaces: ["^enp.*"]
    nodeSelector:
        matchLabels:
            kubernetes.io/os: linux
```

### How It Works

1. **Service Creation**: Create a `LoadBalancer` service
2. **IP Assignment**: Cilium assigns IP from the pool (`10.11.80.0/24`)
3. **ARP Announcement**: Cilium announces the IP via ARP on the network
4. **Traffic Routing**: Network traffic to that IP routes to the service

Example LoadBalancer service:

```yaml
apiVersion: v1
kind: Service
metadata:
    name: my-app
spec:
    type: LoadBalancer
    ports:
        - port: 80
          targetPort: 8080
    selector:
        app: my-app
```

## Gateway API

### External Gateway

```yaml
# k8s/apps/kube-system/cilium/gateway/external.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
    name: external
spec:
    gatewayClassName: cilium
    addresses:
        - type: IPAddress
          value: 10.11.80.80
    listeners:
        - name: https
          protocol: HTTPS
          port: 443
          hostname: "*.sbbh.cloud"
          tls:
              certificateRefs:
                  - kind: Secret
                    name: sbbh-cloud-tls
```

### Internal Gateway

```yaml
# k8s/apps/kube-system/cilium/gateway/internal.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
    name: internal
spec:
    gatewayClassName: cilium
    addresses:
        - type: IPAddress
          value: 10.11.80.81
    listeners:
        - name: https
          protocol: HTTPS
          port: 443
          hostname: "*.sbbh.cloud"
```

### HTTP to HTTPS Redirect

```yaml
# k8s/apps/kube-system/cilium/gateway/redirect.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
    name: httpsredirect
spec:
    parentRefs:
        - name: internal
          sectionName: http
        - name: external
          sectionName: http
    rules:
        - filters:
              - requestRedirect:
                    scheme: https
                    statusCode: 301
                type: RequestRedirect
```

## k8s_gateway Configuration

### Purpose

k8s_gateway provides DNS resolution for Gateway API routes, enabling split DNS functionality where internal clients can resolve `*.sbbh.cloud` domains to appropriate gateways.

### Deployment

```yaml
# k8s/apps/kube-system/k8s-gateway/app/helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
    name: k8s-gateway
spec:
    chart:
        spec:
            chart: k8s-gateway
            version: 2.4.0
            sourceRef:
                kind: HelmRepository
                name: k8s-gateway
    values:
        fullnameOverride: k8s-gateway
        domain: sbbh.cloud
        service:
            type: LoadBalancer
            port: 53
            annotations:
                io.cilium/lb-ipam-ips: 10.11.80.82
        watchedResources:
            - Gateway
            - HTTPRoute
            - Service
        ttl: 300
```

### Split DNS Integration

#### OPNsense Configuration

```yaml
# ansible/playbooks/vm_opnsense.yml
dns:
    domain_overrides:
        - domain: sbbh.cloud
          server: 10.11.80.82
          description: "Forward sbbh.cloud to k8s_gateway"
```

#### DNS Resolution Flow

1. **Internal Client** queries `myapp.sbbh.cloud`
2. **OPNsense** forwards query to k8s_gateway (10.11.80.82)
3. **k8s_gateway** checks Gateway API routes
4. **Returns IP** of appropriate gateway:
    - External routes → `10.11.80.80`
    - Internal routes → `10.11.80.81`
5. **Client connects** to the returned IP

### Gateway Routing Logic

#### Public Applications (External Gateway)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
    name: public-app
spec:
    hostnames: ["public-app.sbbh.cloud"]
    parentRefs:
        - name: external # Uses 10.11.80.80
          namespace: kube-system
```

**Access:** Internet + Internal clients
**DNS Resolution:** `public-app.sbbh.cloud` → `10.11.80.80`

#### Internal Applications (Internal Gateway)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
    name: internal-app
spec:
    hostnames: ["internal-app.sbbh.cloud"]
    parentRefs:
        - name: internal # Uses 10.11.80.81
          namespace: kube-system
```

**Access:** Internal clients only
**DNS Resolution:** `internal-app.sbbh.cloud` → `10.11.80.81`

### Benefits

1. **Automatic DNS Management**: No manual DNS overrides needed
2. **Dynamic Resolution**: DNS responses based on actual Gateway routes
3. **Security**: Internal apps only accessible from internal network
4. **Flexibility**: Same domain (sbbh.cloud) for both internal and external apps

### Example Usage

#### Creating Public Application

```bash
# Create HTTPRoute for public access
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: public-app
  namespace: default
spec:
  hostnames: ["public-app.sbbh.cloud"]
  parentRefs:
    - name: external
      namespace: kube-system
      sectionName: https
  rules:
    - backendRefs:
        - name: my-app-service
          port: 80
EOF
```

**Result**:

- DNS: `public-app.sbbh.cloud` resolves to `10.11.80.80`
- Access: Available from internet + internal network

#### Creating Internal Application

```bash
# Create HTTPRoute for internal access only
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: internal-app
  namespace: default
spec:
  hostnames: ["internal-app.sbbh.cloud"]
  parentRefs:
    - name: internal
      namespace: kube-system
      sectionName: https
  rules:
    - backendRefs:
        - name: my-internal-service
          port: 80
EOF
```

**Result**:

- DNS: `internal-app.sbbh.cloud` resolves to `10.11.80.81`
- Access: Only available from internal network

#### Testing DNS Resolution

```bash
# From internal network
dig @10.11.80.82 public-app.sbbh.cloud   # Returns 10.11.80.80
dig @10.11.80.82 internal-app.sbbh.cloud # Returns 10.11.80.81

# From external network
dig public-app.sbbh.cloud                # Returns public IP (port forwarded)
dig internal-app.sbbh.cloud              # Returns public IP (but not port forwarded)
```

## CoreDNS Configuration

### Custom Configuration

```yaml
# k8s/apps/kube-system/coredns/app/helm/values.yaml
service:
    name: kube-dns
    clusterIP: "10.43.0.10"

servers:
    - zones:
          - zone: .
      plugins:
          - name: kubernetes
            parameters: cluster.local in-addr.arpa ip6.arpa
            configBlock: |-
                pods verified
                fallthrough in-addr.arpa ip6.arpa
          - name: forward
            parameters: . /etc/resolv.conf
          - name: cache
            configBlock: |-
                prefetch 20
                serve_stale
```

### Node Affinity

CoreDNS runs on control plane nodes:

```yaml
affinity:
    nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
                - matchExpressions:
                      - key: node-role.kubernetes.io/control-plane
                        operator: Exists
```

## Using the Network

### Exposing Applications

#### Option 1: LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
    name: my-app-lb
spec:
    type: LoadBalancer
    ports:
        - port: 80
          targetPort: 8080
    selector:
        app: my-app
```

#### Option 2: Gateway API HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
    name: my-app-route
spec:
    hostnames: ["my-app.sbbh.cloud"]
    parentRefs:
        - name: external
          namespace: kube-system
          sectionName: https
    rules:
        - backendRefs:
              - name: my-app
                port: 80
```

### DNS Resolution

#### Internal Services (CoreDNS)

- `my-service.my-namespace.svc.cluster.local`
- `kubernetes.default.svc.cluster.local`

#### External Services (k8s_gateway + OPNsense)

- `*.sbbh.cloud` → k8s_gateway → Gateway API routes
- External DNS via OPNsense → Upstream resolvers

#### DNS Resolution Hierarchy

1. **Internal queries** (.svc.cluster.local) → CoreDNS
2. **Gateway routes** (\*.sbbh.cloud) → k8s_gateway via OPNsense
3. **External domains** → OPNsense → Upstream DNS

## Monitoring

### Cilium Metrics

Available via Prometheus:

- Network policy enforcement
- LoadBalancer IP assignments
- eBPF program statistics
- Connectivity metrics

### Hubble Observability

```bash
# Install Hubble CLI
curl -L --remote-name-all https://github.com/cilium/hubble/releases/latest/download/hubble-linux-amd64.tar.gz
tar xzvfC hubble-linux-amd64.tar.gz /usr/local/bin

# Port forward to Hubble
kubectl port-forward -n kube-system svc/hubble-relay 4245:80

# View network flows
hubble observe --server localhost:4245
```

## Troubleshooting

### Common Network Issues

1. **LoadBalancer IP Not Assigned**:

    ```bash
    # Check IP pool status
    kubectl get ciliumloadbalancerippool

    # Check L2 announcement policy
    kubectl get ciliuml2announcementpolicy

    # View Cilium logs
    kubectl logs -n kube-system -l k8s-app=cilium
    ```

2. **LoadBalancer IP Not Reachable (L2 Announcement Issues)**:

    **Symptoms**: LoadBalancer service shows IP assigned but not reachable from network

    ```bash
    # Check if IP is assigned
    kubectl get svc -A | grep LoadBalancer

    # Test from same network segment (e.g., OPNsense)
    curl -v http://10.11.80.80 --connect-timeout 5

    # Check Cilium L2 announcement status
    kubectl get ciliuml2announcementpolicies -o yaml
    ```

    **Common Causes**:

    - **Controller initialization race condition**: L2 policy created before LoadBalancer services
    - **Network interface mismatch**: Policy targets wrong interface pattern
    - **Timing issues after cluster restore**: Controllers not properly initialized

    **Solution - Recreate L2 Announcement Policy**:

    ```bash
    # Delete existing policy
    kubectl delete ciliuml2announcementpolicies l2-policy

    # Wait a few seconds, then recreate
    kubectl apply -f k8s/apps/kube-system/cilium/app/networks.yaml

    # Verify LoadBalancer IPs are now reachable
    curl -v http://10.11.80.80 --connect-timeout 5
    ```

    **Why This Works**:

    - Cilium's L2 announcement controller watches both policies and services
    - If services exist before policies, controller may not initialize announcements
    - Recreation forces controller to scan existing services and activate announcements
    - Common issue after major cluster restorations or GitOps reinstallations

    **Prevention**:

    - Ensure L2 policies are created before LoadBalancer services
    - Monitor L2 announcement status after cluster maintenance
    - Consider adding reconciliation checks in automation

3. **Gateway Not Responding (L2 Announcement Leader Election Issues)**:

    **Symptoms**: Gateway service exists but connections are refused or timeout

    ```bash
    # Check Gateway status
    kubectl get gateway -A

    # Check LoadBalancer service endpoints (should not show dummy IPs)
    kubectl get endpoints -n kube-system cilium-gateway-internal

    # Test basic connectivity to LoadBalancer IP
    ping -c 3 10.11.80.81
    nmap -sn 10.11.80.81
    ```

    **Root Cause**: Cilium L2 announcement leader election conflicts prevent proper ARP announcements

    **Diagnosis Steps**:

    ```bash
    # Check for L2 announcement errors in Cilium logs
    kubectl logs -n kube-system -l k8s-app=cilium --tail=50 | grep -i "l2\|announce\|leader"

    # Look for these error patterns:
    # - "service not found" warnings
    # - "failed to upsert ok health status"
    # - "error initially creating leader election record"

    # Check current L2 announcement leases
    kubectl get leases -n kube-system | grep l2announce
    ```

    **Solution - Clear Stuck Leader Election**:

    ```bash
    # Delete the problematic lease (replace 'internal' with affected gateway)
    kubectl delete lease -n kube-system cilium-l2announce-kube-system-cilium-gateway-internal

    # Wait 10-15 seconds for re-election
    sleep 15

    # Verify IP becomes reachable
    ping -c 3 10.11.80.81
    curl -v --connect-timeout 5 https://echo-int.sbbh.cloud
    ```

    **Why This Works**:

    - Multiple Cilium nodes compete to become L2 announcer leader for each LoadBalancer IP
    - When gateway is recreated, leader election can get stuck with stale leases
    - Deleting the lease forces re-election and proper L2 ARP announcements
    - Without L2 announcements, the IP exists but isn't reachable on the network

    **Test gateway connectivity**:

    ```bash
    curl -k https://10.11.80.80
    curl -k https://10.11.80.81
    ```

4. **DNS Resolution Issues**:

    ```bash
    # Check CoreDNS pods
    kubectl get pods -n kube-system -l k8s-app=kube-dns

    # Check k8s_gateway pods
    kubectl get pods -n kube-system -l app.kubernetes.io/name=k8s-gateway

    # Test internal DNS resolution
    kubectl run debug --image=nicolaka/netshoot -it --rm
    # Inside pod: nslookup kubernetes.default.svc.cluster.local

    # Test k8s_gateway DNS resolution
    nslookup myapp.sbbh.cloud 10.11.80.82
    ```

5. **k8s_gateway Issues**:

    ```bash
    # Check k8s_gateway service
    kubectl get svc k8s-gateway -n kube-system

    # Check LoadBalancer IP assignment
    kubectl get svc k8s-gateway -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

    # View k8s_gateway logs
    kubectl logs -n kube-system -l app.kubernetes.io/name=k8s-gateway

    # Test DNS query directly
    dig @10.11.80.82 myapp.sbbh.cloud
    ```

6. **Tailscale Route Conflicts**:

    **Symptoms**: LoadBalancer IPs routed through Tailscale instead of local network

    ```bash
    # Check route for LoadBalancer IP
    ip route get 10.11.80.80

    # Check Tailscale subnet advertisements
    tailscale status --json | jq '.Peer[] | {HostName: .HostName, PrimaryRoutes: .PrimaryRoutes}'
    ```

    **Common Issue**: Tailscale peer advertising broad subnet (e.g., `10.11.0.0/16`) that includes LoadBalancer IPs

    **Solution**: Ensure LoadBalancer IPs are accessible via local network by:

    - Testing from same network segment (e.g., from OPNsense)
    - LoadBalancer IPs should work locally even if routed through Tailscale remotely
    - L2 announcements handle local network access regardless of Tailscale routing

### Network Policies

#### Example Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
    name: deny-all-ingress
spec:
    podSelector: {}
    policyTypes:
        - Ingress
```

#### Allow specific traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
    name: allow-frontend-to-backend
spec:
    podSelector:
        matchLabels:
            app: backend
    ingress:
        - from:
              - podSelector:
                    matchLabels:
                        app: frontend
          ports:
              - protocol: TCP
                port: 8080
```

## Automation and Monitoring

### Automated L2 Announcement Lease Cleanup

To prevent L2 announcement leader election conflicts, you can implement automated lease cleanup using a CronJob:

```yaml
# k8s/apps/kube-system/cilium/app/lease-cleanup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
    name: cilium-l2-lease-cleanup
    namespace: kube-system
spec:
    schedule: "*/10 * * * *" # Every 10 minutes
    concurrencyPolicy: Forbid
    successfulJobsHistoryLimit: 1
    failedJobsHistoryLimit: 1
    jobTemplate:
        spec:
            template:
                spec:
                    serviceAccountName: cilium-l2-lease-cleanup
                    restartPolicy: OnFailure
                    containers:
                        - name: lease-cleanup
                          image: bitnami/kubectl:latest
                          command:
                              - /bin/bash
                              - -c
                              - |
                                  set -euo pipefail

                                  echo "Checking for stuck L2 announcement leases..."

                                  # Get all L2 announcement leases
                                  LEASES=$(kubectl get leases -n kube-system --no-headers | grep "cilium-l2announce" | awk '{print $1}')

                                  for lease in $LEASES; do
                                    # Extract gateway name from lease
                                    GATEWAY=$(echo "$lease" | sed 's/cilium-l2announce-kube-system-cilium-gateway-//')
                                    
                                    echo "Checking lease for gateway: $GATEWAY"
                                    
                                    # Check if corresponding LoadBalancer service exists and has proper endpoints
                                    if kubectl get svc "cilium-gateway-$GATEWAY" -n kube-system >/dev/null 2>&1; then
                                      # Get the LoadBalancer IP
                                      LB_IP=$(kubectl get svc "cilium-gateway-$GATEWAY" -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
                                      
                                      if [[ -n "$LB_IP" ]]; then
                                        # Check if the IP is reachable (basic connectivity test)
                                        if ! timeout 5 nc -z "$LB_IP" 443 2>/dev/null && ! timeout 5 nc -z "$LB_IP" 80 2>/dev/null; then
                                          echo "LoadBalancer IP $LB_IP for gateway $GATEWAY is not reachable. Checking lease age..."
                                          
                                          # Get lease age in seconds
                                          LEASE_AGE=$(kubectl get lease "$lease" -n kube-system -o jsonpath='{.metadata.creationTimestamp}' | xargs -I {} date -d {} +%s)
                                          CURRENT_TIME=$(date +%s)
                                          AGE_SECONDS=$((CURRENT_TIME - LEASE_AGE))
                                          
                                          # If lease is older than 5 minutes and IP not reachable, clean it up
                                          if [[ $AGE_SECONDS -gt 300 ]]; then
                                            echo "Deleting stuck lease: $lease (age: ${AGE_SECONDS}s)"
                                            kubectl delete lease "$lease" -n kube-system
                                            echo "Lease deleted. Waiting 15 seconds for re-election..."
                                            sleep 15
                                            
                                            # Verify connectivity after cleanup
                                            if timeout 5 nc -z "$LB_IP" 443 2>/dev/null || timeout 5 nc -z "$LB_IP" 80 2>/dev/null; then
                                              echo "✅ Gateway $GATEWAY ($LB_IP) is now reachable after lease cleanup"
                                            else
                                              echo "⚠️  Gateway $GATEWAY ($LB_IP) still not reachable after lease cleanup"
                                            fi
                                          else
                                            echo "Lease $lease is recent (age: ${AGE_SECONDS}s), not cleaning up"
                                          fi
                                        else
                                          echo "✅ Gateway $GATEWAY ($LB_IP) is reachable"
                                        fi
                                      else
                                        echo "⚠️  No LoadBalancer IP assigned for gateway $GATEWAY"
                                      fi
                                    else
                                      echo "Gateway service cilium-gateway-$GATEWAY not found, deleting orphaned lease: $lease"
                                      kubectl delete lease "$lease" -n kube-system
                                    fi
                                    
                                    echo "---"
                                  done

                                  echo "L2 lease cleanup completed"
---
apiVersion: v1
kind: ServiceAccount
metadata:
    name: cilium-l2-lease-cleanup
    namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
    name: cilium-l2-lease-cleanup
rules:
    - apiGroups: ["coordination.k8s.io"]
      resources: ["leases"]
      verbs: ["get", "list", "delete"]
    - apiGroups: [""]
      resources: ["services"]
      verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
    name: cilium-l2-lease-cleanup
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cilium-l2-lease-cleanup
subjects:
    - kind: ServiceAccount
      name: cilium-l2-lease-cleanup
      namespace: kube-system
```

### L2 Announcement Health Monitoring

Monitor L2 announcement health using a custom metric exporter:

```yaml
# k8s/apps/monitoring/l2-health-monitor/app/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: l2-health-monitor
    namespace: monitoring
spec:
    replicas: 1
    selector:
        matchLabels:
            app: l2-health-monitor
    template:
        metadata:
            labels:
                app: l2-health-monitor
        spec:
            serviceAccountName: l2-health-monitor
            containers:
                - name: monitor
                  image: prom/node-exporter:latest
                  command:
                      - /bin/sh
                      - -c
                      - |
                          while true; do
                            # Check each LoadBalancer service
                            for svc in $(kubectl get svc -A --field-selector spec.type=LoadBalancer -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers); do
                              namespace=$(echo $svc | awk '{print $1}')
                              name=$(echo $svc | awk '{print $2}')
                              ip=$(kubectl get svc $name -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
                              
                              if [[ -n "$ip" ]]; then
                                # Test connectivity
                                if timeout 2 nc -z "$ip" 80 2>/dev/null || timeout 2 nc -z "$ip" 443 2>/dev/null; then
                                  echo "loadbalancer_reachable{namespace=\"$namespace\",service=\"$name\",ip=\"$ip\"} 1"
                                else
                                  echo "loadbalancer_reachable{namespace=\"$namespace\",service=\"$name\",ip=\"$ip\"} 0"
                                fi
                              fi
                            done > /tmp/metrics.prom
                            
                            sleep 30
                          done
                  ports:
                      - containerPort: 8080
                        name: metrics
                  volumeMounts:
                      - name: metrics
                        mountPath: /tmp
            volumes:
                - name: metrics
                  emptyDir: {}
```

### Alerting Rules

Add Prometheus alerts for L2 announcement issues:

```yaml
# k8s/apps/monitoring/prometheus-rules/l2-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
    name: cilium-l2-alerts
    namespace: monitoring
spec:
    groups:
        - name: cilium.l2
          rules:
              - alert: LoadBalancerUnreachable
                expr: loadbalancer_reachable == 0
                for: 2m
                labels:
                    severity: warning
                annotations:
                    summary: "LoadBalancer {{ $labels.service }} in {{ $labels.namespace }} is unreachable"
                    description: "LoadBalancer service {{ $labels.service }} ({{ $labels.ip }}) has been unreachable for more than 2 minutes. This may indicate L2 announcement issues."

              - alert: CiliumL2LeaseStuck
                expr: increase(kube_lease_renew_errors_total{lease=~"cilium-l2announce.*"}[5m]) > 0
                for: 1m
                labels:
                    severity: critical
                annotations:
                    summary: "Cilium L2 announcement lease {{ $labels.lease }} has renewal errors"
                    description: "L2 announcement lease renewal is failing, which may cause LoadBalancer IPs to become unreachable."
```

## Security Considerations

### Network Segmentation

- **Pod-to-pod**: Controlled via NetworkPolicies
- **Ingress**: Gateway API with TLS termination
- **Egress**: Default allow (can be restricted)

### TLS Encryption

- **Gateway → Pod**: TLS termination at gateway
- **Pod → External**: TLS for external APIs
- **Control Plane**: TLS everywhere (Talos default)

### Firewall Integration

- **OPNsense**: North-south traffic control
- **Cilium**: East-west traffic control
- **Network Policies**: Micro-segmentation
