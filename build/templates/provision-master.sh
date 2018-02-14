#!/bin/bash

set -e

if [ -f /etc/kubernetes/pki/ca.key ]
then
  chmod 600 /etc/kubernetes/pki/ca.key
  chmod 644 /etc/kubernetes/pki/ca.crt
  chmod 600 /etc/kubernetes/pki/front-proxy-ca.key
  chmod 644 /etc/kubernetes/pki/front-proxy-ca.crt
fi

# install cfssl for etcd client/peer certs
#curl -sL -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
#curl -sL -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
#chmod 755 /usr/local/bin/cfssl /usr/local/bin/cfssljson

# hack for adfs access :(
#echo "203.34.100.136	adfs.myob.com.au" >> /etc/hosts

PEER_NAME=$(hostname)
PRIVATE_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')

echo
echo "generating etcd certificate/key pairs"
cwd=`pwd`
cd /etc/kubernetes/pki/etcd/
sed -i 's/HOSTN/'"$PEER_NAME"'/' etcd-csr.json
sed -i 's/IPADDR/'"$PRIVATE_IP"'/' etcd-csr.json
cfssl gencert -ca=../ca.crt -ca-key=../ca.key -config=../ca-config.json -profile=server etcd-csr.json | cfssljson -bare server
cfssl gencert -ca=../ca.crt -ca-key=../ca.key -config=../ca-config.json -profile=peer etcd-csr.json | cfssljson -bare peer

echo
echo "running kubeadm init"
kubeadm init --config=${k8s_kubeadm_config}

export KUBECONFIG=/etc/kubernetes/admin.conf

case ${k8s_podnetwork} in
	flannel)
		# flannel
    echo "installing cni network flannel"
		kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
		;;
	canal)
		# canal
    echo "installing cni network canal"
		kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.7/rbac.yaml
		kubectl apply -f https://raw.githubusercontent.com/projectcalico/canal/master/k8s-install/1.7/canal.yaml
		;;
  calico)
		# calico
    echo "installing cni network calico"
		kubectl apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
		;;
  weave)
		# weave
    echo "installing cni network weave"
		kubever=`kubectl version | base64 | tr -d '\n'`
		kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
		;;
  *)
		# flannel
    echo "installing cni network flannel"
		kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
		;;
esac
