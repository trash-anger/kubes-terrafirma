# kubes-terrafirma

## vsphere + terraform + kubeadm == kubes-terrafirma

Un projet pour aider à provisionner un cluster kubernetes sur vsphere.

ça utilise terraform et kubeadm

## Comment?

* installer docker et docker-compose locallement

* construire un template de vm esxi avec docker, kubeadm, kubectl et kubelet  d'installés. Voir : configuration [vm-de-base](vm-base.md) pour CentOS 7.

* générer un jeton kubeadm pour les nœuds avec la commande :

  ```
  make token
  ```
  Enregistrer les jetons résultant pour la variable d'entrée `k8s_bootstrap_token`

* mettre à jour les variables d'entrées terraform : 

  ```
  cp build/global.tfvars.example build/global.tfvars
  cp build/environment.tfvars.example build/<environment name>.tfvars
  vi build/global.tfvars  build/<environment name>.tfvars
  ```

* Générer un certificat "ca" et "admin cert"

  ```
  make ca-<environment name> clustername=<cluster name that matches terraform variable k8s_cluster_name>
  ```
  
* reseigner quelques infos sensibles en variables d'environement pour que terraform puisse les récupérer : 

  ```
  TF_VAR_k8s_root_password="SuperSecretSquirrelRootPassword"
  TF_VAR_vsphere_password="SuperSecretSquirrelVspherePassword"

  export TF_VAR_k8s_root_password TF_VAR_vsphere_password
  ```

* Regarder si la chance est avec nous :

  ```
  make plan-<environment name>
  ```

* Construire un cluster k8s (k8s = kebernetes) 

  ```
  make apply-<environment name>
  ```

* détruire le cluster k8s

  ```
  make destroy-<environment name>
  ```

## Load Balancer??

You will probably want a load balancer to manage traffic to your ingress controller for your apps.
Or if your ingress controller is a daemonset and uses a NodePort service using ports 80 and 443, then you can probably get away with round robin dns pointing to all your nodes.

If you have an f5, you can use [f5er](https://github.com/pr8kerl/f5er) to create the required F5 resources.

* Copy the file **f5/example-environment.json** to **<envirnment>.json** and adjeust the settings.

* Configure your F5 credentials in a config file

  ```
  mkdir ~/.f5
  cat <<EOF > ~/.f5/f5.bla 
  {
  "device": "192.168.1.100",
  "username": "admin",
  "passwd": "letmeinplease"
  }
  EOF
  ```

* create your F5 load balancer stack

  ```
  make f5er-add-<environment>
  ```
