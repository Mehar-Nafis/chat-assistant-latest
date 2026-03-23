# Insurance Chat Assistant — OpenShift Helm Chart

Deploys the complete Insurance Chat Assistant stack to OpenShift using images from
[`lakshmilavanya2001/insurance-chat-assistant`](https://hub.docker.com/r/lakshmilavanya2001/insurance-chat-assistant).

---

## Image Tag Conventions

Every service uses a separate tag on the same DockerHub repository:

| Service | Image |
|---|---|
| chain-server | `lakshmilavanya2001/insurance-chat-assistant:chain-server` |
| catalog-retriever | `lakshmilavanya2001/insurance-chat-assistant:catalog-retriever` |
| memory-retriever | `lakshmilavanya2001/insurance-chat-assistant:memory-retriever` |
| rails | `lakshmilavanya2001/insurance-chat-assistant:rails` |
| frontend | `lakshmilavanya2001/insurance-chat-assistant:frontend` |
| user-management | `lakshmilavanya2001/insurance-chat-assistant:user-management` |
| notification-agent | `lakshmilavanya2001/insurance-chat-assistant:notification-agent` |
| text-to-sql-agent | `lakshmilavanya2001/insurance-chat-assistant:text-to-sql-agent` |

> Third-party images (nginx, milvus, etcd, minio, postgres, mongo) are pulled directly from their public registries.

---

## Prerequisites

- OpenShift 4.x cluster with `oc` CLI logged in
- Helm 3.x installed
- NVIDIA API keys for LLM and Embeddings NIMs

---

## Quick Deploy

### 1. Create a namespace

```bash
oc new-project insurance-assistant
```

### 2. Set your API keys

```bash
# Edit values.yaml and fill in your keys, OR use --set flags:
helm install insurance-assistant ./helm-chart \
  --set env.llmApiKey="YOUR_LLM_API_KEY" \
  --set env.embedApiKey="YOUR_EMBED_API_KEY" \
  --set env.railApiKey="YOUR_RAIL_API_KEY"
```

### 3. (Optional) Set your StorageClass

```bash
# List available storage classes
oc get storageclass

# Then set in values.yaml:
# persistence:
#   storageClass: "your-storage-class"
```

### 4. Install

```bash
helm install insurance-assistant ./helm-chart \
  --namespace insurance-assistant \
  --set env.llmApiKey="nvapi-xxx" \
  --set env.embedApiKey="nvapi-xxx" \
  --set env.railApiKey="nvapi-xxx" \
  --set persistence.storageClass="gp2"
```

### 5. Check status

```bash
oc get pods -n insurance-assistant
oc get route -n insurance-assistant
```

### 6. Access the application

```bash
# Get the Route URL
oc get route insurance-assistant -o jsonpath='{.spec.host}'
```

Open the URL in your browser — you'll see the Login page.

---

## Upgrade

```bash
helm upgrade insurance-assistant ./helm-chart \
  --namespace insurance-assistant \
  --set env.llmApiKey="nvapi-xxx" \
  --set env.embedApiKey="nvapi-xxx" \
  --set env.railApiKey="nvapi-xxx"
```

## Uninstall

```bash
helm uninstall insurance-assistant -n insurance-assistant
# PVCs are NOT deleted automatically (to preserve data)
oc delete pvc -l app.kubernetes.io/instance=insurance-assistant -n insurance-assistant
```

---

## OpenShift-Specific Notes

### Security Context Constraints (SCC)
- All containers run with `securityContext: {}` (OpenShift assigns UIDs automatically)
- No hardcoded `runAsUser` — compatible with `restricted` SCC
- Nginx listens on port **8080** instead of 80 (non-root requirement)

### Route vs Ingress
- `route.enabled: true` (default) — uses OpenShift native Route with TLS edge termination
- `ingress.enabled: false` (default) — standard K8s ingress disabled

### Custom Route Hostname
```yaml
route:
  host: "insurance.apps.your-cluster.example.com"
```

---

## Services Deployed

| Service | Port | Purpose |
|---|---|---|
| chain-server | 8009 | AI orchestration (FastAPI + LangGraph) |
| catalog-retriever | 8010 | RAG / Milvus semantic search |
| memory-retriever | 8011 | Conversation memory |
| rails | 8012 | NeMo Guardrails (content safety) |
| user-management | 8014 | Auth: signup/login/profile |
| notification-agent | 8015 | Email confirmations |
| text-to-sql-agent | 8017 | NL→SQL claims queries |
| frontend | 3000 | React/TypeScript UI |
| nginx | 8080 | Reverse proxy (exposed via Route) |
| postgres | 5432 | Structured data (policies, claims) |
| mongodb | 27017 | User credentials and profiles |
| milvus | 19530 | Vector similarity search |
| etcd | 2379 | Milvus metadata |
| minio | 9000 | Milvus object storage |