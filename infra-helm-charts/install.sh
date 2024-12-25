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

exit
kubectl create ns argocd
kubectl apply -f argo-dev.yaml -n argocd