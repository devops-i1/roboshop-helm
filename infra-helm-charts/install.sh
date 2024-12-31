aws eks update-kubeconfig --name dev-eks
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade -i ngx-ingres ingress-nginx/ingress-nginx -f ingress.yaml

LOAD_BALANCER=$(kubectl get svc ngx-ingres-ingress-nginx-controller | grep ngx-ingres-ingress-nginx-controller | awk '{print $4}')

while true ; do
  echo "Waiting for Load Balancer to come to Active"
  nslookup $LOAD_BALANCER &>/dev/null
  if [ $? -eq 0 ]; then break ; fi
  sleep 5
done

kubectl apply -f external-dns-dev.yaml
sleep 15

kubectl create ns argocd
kubectl apply -f argo-dev.yaml -n argocd

while true ; do
  argocd admin initial-password -n argocd &>/dev/null
  if [ $? -eq 0 ]; then break ; fi
  sleep 5
done

## End
echo
echo
echo
echo "ArgoCD Password : $(argocd admin initial-password -n argocd | head -1)"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install pstack prometheus-community/kube-prometheus-stack -f pstack-dev.yaml