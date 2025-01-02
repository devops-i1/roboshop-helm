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

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install pstack prometheus-community/kube-prometheus-stack -f pstack-dev.yaml

# grafana default username / password  -  admin / prom-operator

kubectl create -f https://download.elastic.co/downloads/eck/2.13.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.13.0/operator.yaml
helm install elk elastic/eck-stack -n elastic-stack --create-namespace

ES_PASSWORD=$(kubectl get secrets -n elastic-stack elasticsearch-es-elastic-user -o json | jq '.data.elastic' | sed -e 's/"//g' | base64 --decode)
sed -e "s/ES_PASSWORD/${ES_PASSWORD}/" eck.yaml >/tmp/eck.yaml
kubectl apply -f /tmp/eck.yaml


## End
echo
echo
echo
echo "ArgoCD Password : $(argocd admin initial-password -n argocd | head -1)"
echo "Grafana Username / Password : admin  / prom-operator"
echo "Elastic Username / Password : elastic  / $(kubectl get secrets -n elastic-stack elasticsearch-es-elastic-user -o json | jq '.data.elastic' | sed -e 's/"//g' | base64 --decode)"