# ArgoCD Demo Project

A complete Kubernetes project demonstrating GitOps deployment with ArgoCD that can be run locally.

## Project Structure

```
argocd-demo-project/
├── app/                    # Sample application
│   ├── index.js
│   ├── package.json
│   └── Dockerfile
├── k8s-manifests/          # Kubernetes manifests
│   ├── namespace.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── argocd/                 # ArgoCD application definition
    └── application.yaml
```

## Prerequisites

- Docker Desktop or Docker Engine
- kubectl CLI
- Git

## Setup Instructions

### Step 1: Set up Local Kubernetes Cluster

You can use either **minikube** or **kind** (Kubernetes in Docker).

#### Option A: Using Minikube

```bash
# Install minikube (if not already installed)
# macOS
brew install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start minikube
minikube start --cpus=4 --memory=8192 --driver=docker

# Verify cluster is running
kubectl cluster-info
```

#### Option B: Using kind

```bash
# Install kind (if not already installed)
# macOS
brew install kind

# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create a kind cluster
kind create cluster --name argocd-demo

# Verify cluster is running
kubectl cluster-info --context kind-argocd-demo
```

### Step 2: Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Verify installation
kubectl get pods -n argocd
```

### Step 3: Access ArgoCD UI

```bash
# Port forward the ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# In a new terminal, get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

Access ArgoCD UI:
- URL: https://localhost:8080
- Username: `admin`
- Password: (use the password from the command above)

### Step 4: Push Project to Git Repository

```bash
# Initialize git repository (if not already done)
cd argocd-demo-project
git init
git add .
git commit -m "Initial commit"

# Create a new repository on GitHub/GitLab/Bitbucket
# Then push your code
git remote add origin https://github.com/YOUR_USERNAME/argocd-demo-project.git
git branch -M main
git push -u origin main
```

### Step 5: Update ArgoCD Application

Edit `argocd/application.yaml` and update the `repoURL` with your Git repository URL:

```yaml
source:
  repoURL: https://github.com/YOUR_USERNAME/argocd-demo-project
```

### Step 6: Deploy Application with ArgoCD

#### Method 1: Using kubectl

```bash
# Apply the ArgoCD application manifest
kubectl apply -f argocd/application.yaml

# Check application status
kubectl get applications -n argocd

# Watch the sync status
kubectl get applications -n argocd -w
```

#### Method 2: Using ArgoCD UI

1. Log in to ArgoCD UI (https://localhost:8080)
2. Click "NEW APP"
3. Fill in the details:
   - Application Name: `demo-app`
   - Project: `default`
   - Sync Policy: `Automatic`
   - Repository URL: Your Git repository URL
   - Path: `k8s-manifests`
   - Cluster URL: `https://kubernetes.default.svc`
   - Namespace: `argocd-demo`
4. Click "CREATE"

#### Method 3: Using ArgoCD CLI

```bash
# Install ArgoCD CLI
# macOS
brew install argocd

# Linux
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Login to ArgoCD
argocd login localhost:8080

# Create application
argocd app create demo-app \
  --repo https://github.com/YOUR_USERNAME/argocd-demo-project.git \
  --path k8s-manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd-demo \
  --sync-policy automated

# Sync the application
argocd app sync demo-app
```

### Step 7: Verify Deployment

```bash
# Check if namespace is created
kubectl get namespace argocd-demo

# Check pods
kubectl get pods -n argocd-demo

# Check services
kubectl get svc -n argocd-demo

# Access the application
# For minikube:
minikube service demo-app-service -n argocd-demo

# For kind:
kubectl port-forward -n argocd-demo svc/demo-app-service 8081:80
# Then access http://localhost:8081
```

## Testing GitOps Workflow

1. Make a change to the Kubernetes manifests (e.g., change replica count in `deployment.yaml`):

```bash
# Edit deployment.yaml
sed -i 's/replicas: 2/replicas: 3/' k8s-manifests/deployment.yaml

# Commit and push
git add k8s-manifests/deployment.yaml
git commit -m "Scale to 3 replicas"
git push
```

2. Watch ArgoCD automatically sync the changes:

```bash
# Watch the application sync
kubectl get applications -n argocd -w

# Or use ArgoCD CLI
argocd app get demo-app --watch
```

3. Verify the changes:

```bash
kubectl get deployment -n argocd-demo
# You should see 3 replicas now
```

## Useful Commands

### ArgoCD

```bash
# List all applications
argocd app list

# Get application details
argocd app get demo-app

# Sync application manually
argocd app sync demo-app

# Delete application
argocd app delete demo-app

# Refresh application (fetch latest from Git)
argocd app refresh demo-app

# View application history
argocd app history demo-app

# Rollback to previous version
argocd app rollback demo-app <revision-number>
```

### Kubernetes

```bash
# View logs
kubectl logs -n argocd-demo -l app=demo-app

# Describe deployment
kubectl describe deployment demo-app -n argocd-demo

# Delete namespace (cleanup)
kubectl delete namespace argocd-demo
```

## Cleanup

```bash
# Delete the ArgoCD application
kubectl delete -f argocd/application.yaml

# Or using ArgoCD CLI
argocd app delete demo-app

# Delete ArgoCD
kubectl delete namespace argocd

# Delete the local cluster
# For minikube:
minikube delete

# For kind:
kind delete cluster --name argocd-demo
```

## Customization

### Using Your Own Application

Replace the `nginx:alpine` image in `k8s-manifests/deployment.yaml` with your own image:

```yaml
containers:
- name: demo-app
  image: your-registry/your-app:tag
```

### Adding More Resources

Add more Kubernetes resources in the `k8s-manifests/` directory:
- ConfigMaps
- Secrets
- Ingress
- HorizontalPodAutoscaler

ArgoCD will automatically detect and deploy them.

## Troubleshooting

### ArgoCD pods not starting

```bash
# Check pod status
kubectl get pods -n argocd

# Check logs
kubectl logs -n argocd <pod-name>

# Increase resources if needed
# Edit minikube/kind cluster configuration
```

### Application not syncing

```bash
# Check application status
argocd app get demo-app

# Check sync errors
kubectl describe application demo-app -n argocd

# Manual sync
argocd app sync demo-app --force
```

### Cannot access application

```bash
# Check service
kubectl get svc -n argocd-demo

# Check pods are running
kubectl get pods -n argocd-demo

# Check logs
kubectl logs -n argocd-demo -l app=demo-app
```

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitOps Principles](https://www.gitops.tech/)

## License

MIT License
