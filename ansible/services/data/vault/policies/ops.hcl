# Homelab operations - KV v2 secrets engine
path "ops/data/*" {
  capabilities = ["read"]
}

path "ops/metadata/*" {
  capabilities = ["read", "list"]
}
