# Quick Start Guide

Get up and running with ArgoCD in 5 minutes!

## Prerequisites

- Docker Desktop or Docker Engine running
- kubectl installed
- make installed (optional, but recommended)

## Quick Setup (Using Make)

### 1. Start Local Kubernetes Cluster

**Option A: Minikube**
```bash
make setup-minikube
```

**Option B: Kind**
```bash
make setup-kind
```

This will:
- Create a local Kubernetes cluster
- Install ArgoCD
- Wait for everything to be ready

### 2. Get ArgoCD Password

```bash
make get-password
```

Save this password - you'll need it to log in.

### 3. Access ArgoCD UI

In a new terminal window:
```bash
make port-forward
```

Then open your browser to: **https://localhost:8080**
- Username: `admin`
- Password: (from step 2)

### 4. Push to Git Repository

```bash
# Initialize git (if not done)
git init
git add .
git commit -m "Initial commit"

# Create a new repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/argocd-demo-project.git
git branch -M main
git push -u origin main
```

### 5. Update Application Configuration

Edit `argocd/application.yaml` and change the repo URL:
```yaml
source:
  repoURL: https://github.com/YOUR_USERNAME/argocd-demo-project
```

Commit and push:
```bash
git add argocd/application.yaml
git commit -m "Update repo URL"
git push
```

### 6. Deploy Application

```bash
make deploy
```

### 7. Check Status

```bash
make status
```

You should see your application syncing in ArgoCD!

## Testing GitOps

1. Make a change (e.g., scale replicas):
```bash
sed -i 's/replicas: 2/replicas: 3/' k8s-manifests/deployment.yaml
git add k8s-manifests/deployment.yaml
git commit -m "Scale to 3 replicas"
git push
```

2. Watch ArgoCD automatically sync the change in the UI!

## Useful Commands

```bash
make help              # Show all available commands
make status            # Check application status
make logs              # View application logs
make clean-app         # Delete application
make clean-minikube    # Delete cluster (minikube)
make clean-kind        # Delete cluster (kind)
```

## Manual Setup (Without Make)

If you prefer not to use Make, follow the detailed instructions in [README.md](README.md).

## Troubleshooting

**Port 8080 already in use?**
```bash
# Use a different port
kubectl port-forward svc/argocd-server -n argocd 9090:443
# Then access https://localhost:9090
```

**Can't find password secret?**
```bash
# Wait a bit more for ArgoCD to initialize
kubectl get pods -n argocd
# All pods should be Running
```

**Application not syncing?**
- Check the repo URL in `argocd/application.yaml`
- Make sure your Git repo is public (or configure SSH keys)
- Check application status in ArgoCD UI

## Next Steps

- Read the full [README.md](README.md) for detailed information
- Customize the application in `k8s-manifests/`
- Try adding ConfigMaps, Secrets, or Ingress resources
- Explore ArgoCD features like rollback, health checks, and sync waves

Happy GitOps! 🚀
