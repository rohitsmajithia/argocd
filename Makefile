.PHONY: help start-minikube start-kind install-argocd port-forward get-password deploy status logs clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

start-minikube: ## Start minikube cluster
	@echo "Starting minikube cluster..."
	minikube start --cpus=4 --memory=8192 --driver=docker
	@echo "Cluster started successfully!"

start-kind: ## Start kind cluster
	@echo "Starting kind cluster..."
	kind create cluster --name argocd-demo
	@echo "Cluster started successfully!"

install-argocd: ## Install ArgoCD
	@echo "Creating ArgoCD namespace..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	@echo "Installing ArgoCD..."
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "Waiting for ArgoCD to be ready..."
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
	@echo "ArgoCD installed successfully!"

port-forward: ## Port forward ArgoCD UI to localhost:8080
	@echo "Port forwarding ArgoCD UI to https://localhost:8080"
	kubectl port-forward svc/argocd-server -n argocd 8080:443

get-password: ## Get ArgoCD admin password
	@echo "ArgoCD Admin Password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

deploy: ## Deploy application to ArgoCD
	@echo "Deploying application..."
	kubectl apply -f argocd/application.yaml
	@echo "Application deployed! Check status with: make status"

status: ## Check application status
	@echo "Application status:"
	kubectl get applications -n argocd
	@echo ""
	@echo "Pods in argocd-demo namespace:"
	kubectl get pods -n argocd-demo 2>/dev/null || echo "Namespace not yet created"

logs: ## View application logs
	kubectl logs -n argocd-demo -l app=demo-app --tail=50 -f

clean-app: ## Delete the application from ArgoCD
	kubectl delete -f argocd/application.yaml
	kubectl delete namespace argocd-demo --ignore-not-found=true

clean-argocd: ## Uninstall ArgoCD
	kubectl delete namespace argocd

clean-minikube: ## Delete minikube cluster
	minikube delete

clean-kind: ## Delete kind cluster
	kind delete cluster --name argocd-demo

setup-minikube: start-minikube install-argocd ## Complete setup with minikube
	@echo ""
	@echo "Setup complete! Next steps:"
	@echo "1. Run 'make get-password' to get ArgoCD admin password"
	@echo "2. Run 'make port-forward' in another terminal"
	@echo "3. Access ArgoCD UI at https://localhost:8080"
	@echo "4. Update argocd/application.yaml with your Git repo URL"
	@echo "5. Run 'make deploy' to deploy your application"

setup-kind: start-kind install-argocd ## Complete setup with kind
	@echo ""
	@echo "Setup complete! Next steps:"
	@echo "1. Run 'make get-password' to get ArgoCD admin password"
	@echo "2. Run 'make port-forward' in another terminal"
	@echo "3. Access ArgoCD UI at https://localhost:8080"
	@echo "4. Update argocd/application.yaml with your Git repo URL"
	@echo "5. Run 'make deploy' to deploy your application"
