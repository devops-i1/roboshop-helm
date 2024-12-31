argocd login $(kubectl get ingress -A | grep argocd | awk '{print $4}') --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo) --insecure --grpc-web

for app in frontend catalogue cart user payment shipping dispatch ; do
   argocd app create ${app}  --repo https://github.com/devops-i1/roboshop-helm --path chart --dest-namespace default --dest-server https://kubernetes.default.svc --grpc-web --values ../values/${app}.yaml
   argocd app sync ${app}
done
