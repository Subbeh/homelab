# Homelab

![Home](https://img.shields.io/uptimerobot/status/m794403672-d8d77f6c6e04bba27fcbcd9c?label=home)

## :wrench: Hardware

| Device                   | OS Disk Size | Data Disk Size | Cores | Ram  | Operating System | Purpose           |
| ------------------------ | ------------ | -------------- | ----- | ---- | ---------------- | ----------------- |
| NUC 12 Pro (i7 1260P)    | 1TB SSD      | 1x 500GB SSD   | 16    | 64GB | Proxmox          | VMs               |
| Dell OptiPlex (i5-8500T) | 1TB SSD      | 1x 500GB SSD   | 6     | 32GB | Proxmox          | VMs               |
| Dell OptiPlex (i5-6500T) | 256GB SSD    | 1x 500GB SSD   | 4     | 16GB | Proxmox          | VMs               |
| Topton n5105 NAS         | 1TB SSD      | 2x 6TB HDD     | 4     | 32GB | Proxmox          | NAS / VMs         |
| Topton n5105             | 128GB SSD    | -              | 4     | 16GB | OPNsense         | Firewall / Router |
| RPi 4                    | 32GB         | -              | 4     | 4GB  | PiKVM            | Network KVM       |
| Unifi Swtich Lite 16 PoE | -            | -              | -     | -    | -                | Network Switch    |

## :art: Infrastructure

[<img src="https://github.com/Subbeh/homelab/assets/1278086/eea39baa-0a01-45d6-8515-d584828917e8" alt="Infrastructure" width="70%" height="70%" title="Infrastructure">](https://github.com/Subbeh/homelab/assets/1278086/90cc1f05-051c-4ce2-a285-510d1363caf8)

## :satellite: Networking

| VLAN       | ID  |
| ---------- | --- |
| Management | 1   |
| DMZ        | 5   |
| Servers    | 10  |
| VM         | 20  |
| Kubernetes | 80  |
| Clients    | 100 |
| Guest      | 200 |

## :open_file_folder: Repository Structure

```text
📁 homelab
├──📁 ansible
│   ├──📁 apps
│   ├──📁 playbooks
│   ├──📁 roles
│   └──📁 tasks
├──📁 k8s
│   ├──📁 resources
│   └──📁 management
│       ├──📁 apps
│       ├──📁 argocd
│       └──📁 external-secrets
└──📁 terraform
    ├──📁 modules
    └──📁 pve
```

## :computer: Core Components

<table>
  <tr>
    <th></th>
    <th>Name</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><img width="32" src="https://github.com/simple-icons/simple-icons/raw/master/icons/opnsense.svg"></td>
    <td><a href="https://opnsense.org">OPNsense</a></td>
    <td>Open source firewall and routing software</td>
  </tr>
  <tr>
    <td><img width="32" src="https://github.com/simple-icons/simple-icons/raw/master/icons/proxmox.svg"></td>
    <td><a href="https://www.proxmox.com">Proxmox</a></td>
    <td>Hyper-converged infrastructure open-source software</td>
  </tr>
  <tr>
    <td><img width="32" src="https://www.vectorlogo.zone/logos/debian/debian-icon.svg"></td>
    <td><a href="https://www.debian.com">Debian</a></td>
    <td>Linux distribution</td>
  </tr>
  <tr>
    <td><img width="32" src="https://vectorlogo.zone/logos/ansible/ansible-icon.svg"></td>
    <td><a href="https://ansible.com">Ansible</a></td>
    <td>Bare metal provisioning and configuration</td>
  </tr>
  <tr>
    <td><img width="32" src="https://vectorlogo.zone/logos/terraformio/terraformio-icon.svg"></td>
    <td><a href="https://terraform.io">Terraform</a></td>
    <td>Provision resources on external environments</td>
  </tr>
  <tr>
    <td><img width="32" src="https://www.vectorlogo.zone/logos/giteaio/giteaio-icon.svg"></td>
    <td><a href="https://www.gitea.com">Gitea</a></td>
    <td>Open-source Git hosting and artifact platform</td>
  </tr>
  <tr>
    <td><img width="32" src="https://vectorlogo.zone/logos/kubernetes/kubernetes-icon.svg"></td>
    <td><a href="https://kubernetes.io">Kubernetes</a></td>
    <td>Orchestration system for managing containers</td>
  </tr>
  <tr>
    <td><img width="32" src="https://github.com/cncf/artwork/raw/main/projects/metallb/icon/color/metallb-icon-color.svg"></td>
    <td><a href="https://metallb.universe.tf/">MetalLB</a></td>
    <td>Load balancer provisioning service for bare metal LBs</td>
  </tr>
  <tr>
    <td><img width="32" src="https://github.com/cncf/landscape/raw/master/hosted_logos/kubevip.svg"></td>
    <td><a href="https://kube-vip.io/">Kube-vip</a></td>
    <td>Virtual IP and load balancer for both the control plane (for building a highly-available cluster) and Kubernetes Services</td>
  </tr>
  <tr>
    <td><img width="32" src="https://gitlab.com/celebdor/design/-/raw/master/logos/calico_head.svg?inline=false"></td>
    <td><a href="https://docs.tigera.io/calico/latest/about/">Calico</a></td>
    <td>Container Network Interface for Kubernetes</td>
  </tr>
  <tr>
    <td><img width="32" src="https://vectorlogo.zone/logos/traefikio/traefikio-icon.svg"></td>
    <td><a href="https://traefik.io">Traefik</a></td>
    <td>Cloud native ingress controller for Kubernetes</td>
  </tr>
  <tr>
    <td><img width="32" src="https://www.vectorlogo.zone/logos/argoprojio/argoprojio-icon.svg"></td>
    <td><a href="https://argo-cd.readthedocs.io/">Argo CD</a></td>
    <td>Declarative GitOps Continuous Delivery for Kubernetes</td>
  </tr>
  <tr>
    <td><img width="32" src="https://www.vectorlogo.zone/logos/droneio/droneio-icon.svg"></td>
    <td><a href="https://www.drone.io">Drone CI</a></td>
    <td>Self-service Continuous Integration platform</td>
  </tr>
  <tr>
    <td><img width="32" src="https://github.com/vscode-icons/vscode-icons/raw/master/icons/file_type_doppler.svg"></td>
    <td><a href="https://www.doppler.com">Doppler</a></td>
    <td>Secrets Management platform</td>
  </tr>
  <tr>
    <td><img width="32" src="https://github.com/cncf/landscape/raw/master/hosted_logos/external-secrets.svg"></td>
    <td><a href="https://external-secrets.io/latest/">External Secrets</a></td>
    <td>Kubernetes operator that integrates external secret management systems</td>
  </tr>
  <tr>
    <td><img width="32" src="https://github.com/cncf/artwork/raw/main/projects/longhorn/icon/color/longhorn-icon-color.svg"></td>
    <td><a href="https://longhorn.io/">Longhorn</a></td>
    <td>Cloud native distributed block storage for Kubernetes</td>
  </tr>
  <tr>
    <td><img width="32" src="https://www.vectorlogo.zone/logos/minioio/minioio-icon.svg"></td>
    <td><a href="https://min.io/">Minio</a></td>
    <td>S3 compatible object store</td>
  </tr>
  <tr>
    <td><img width="32" src="https://github.com/cncf/artwork/raw/main/projects/cert-manager/icon/color/cert-manager-icon-color.svg"></td>
    <td><a href="https://cert-manager.io/">Cert-manager</a></td>
    <td>Cloud native certificate management for Kubernetes</td>
  </tr>
  <tr>
    <td><img width="32" src="https://github.com/Subbeh/homelab/assets/1278086/b8763b5e-5995-470e-831b-1baadc6362dd"></td>
    <td><a href="https://www.crowdsec.net/">CrowdSec</a></td>
    <td>Open-source Intrusion Detection and Prevention system</td>
  </tr>
  <tr>
    <td><img width="32" src="https://goauthentik.io/img/icon_top_brand_colour.svg"></td>
    <td><a href="">Authentik</a></td>
    <td>SSO for the services that support LDAP/SAML/OIDC.</td>
  </tr>
  <tr>
    <td><img width="32" src="https://www.vectorlogo.zone/logos/prometheusio/prometheusio-icon.svg"></td>
    <td><a href="https://prometheus.io/">Prometheus</a></td>
    <td>Monitoring system and time series database</td>
  </tr>
  <tr>
    <td><img width="32" src="https://www.vectorlogo.zone/logos/grafana/grafana-icon.svg"></td>
    <td><a href="https://grafana.com/">Grafana</a></td>
    <td>Open-source analytics and interactive visualization web application</td>
  </tr>
  <tr>
    <td><img width="32" src="https://gitlab.com/prism-break/prism-break/-/raw/master/source/assets/logos/borgbackup.svg"></td>
    <td><a href="https://www.borgbackup.org/">BorgBackup</a></td>
    <td>Deduplicating archiver with compression and encryption</td>
  </tr>
</table>

## :incoming_envelope: CI/CD

![cicd](https://github.com/Subbeh/homelab/assets/1278086/16832140-420d-4dac-b256-83fa36d7c6ed)
