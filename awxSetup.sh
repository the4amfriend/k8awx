#you'll need to run this script in the same folder where your kustomization file is.
#you'll also need to have the files in this repo added to the k8awx folder.


mkdir $HOME/k8awx/
cd $HOME/k8awx/

curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash 

export PATH=$PATH:$HOME/k8awx/

git clone https://github.com/ansible/awx-operator.git

cd $HOME/k8awx/awx-operator

ver=$(git describe --tags --abbrev=0)
cd $HOME/k8awx/
sed -i s/0.*/$ver/ kustomization.yaml

kustomize build . | kubectl apply -f -

#once the kustomization is complete, we create the ingress-controller service. Note that deploy.yaml must have hostNetwork: true, nodePort: 31145(or whatever port your HAProxy offloads ssl from)

kubectl apply -f deploy.yaml

#we wait for the deployment to complete.
#to see the deployment live, you can Ctrl+Z then run 'kubectl logs - -f deployments/awx-operator-controller-manager -c awx-manager -n awx'
#once the logs complete, Ctrl+C then fg your way back into the script.
until  kubectl logs --since 5m -f deployments/awx-operator-controller-manager -c awx-manager -n awx | grep -m1 -C1 "failed=0"
do
       echo waiting for deployment to finish
done

kubectl apply -f ingress.yaml -n awx
#you should check the site now. If the output of the below changes, make sure you can still access the site.if you can't re-run the command above.
kubectl get ingress -n awx -w

