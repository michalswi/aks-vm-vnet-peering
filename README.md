# Private AKS cluster

By default AKS cluster is created using a public IP for the kubernetes API server. Once **private cluster** is enabled **only** machines (in this example single VM) connected to AKS VNet has access/can connect to the API Server.  

What we have here is single VM and AKS deployed in separate Virtual Networks (VNets) using Virtual Network Peering.

Official Azure documentation is available [here](https://docs.microsoft.com/en-us/azure/aks/private-clusters).

Similar topics related to access to AKS:  
[AKS + Azure Active Directory](https://github.com/michalswi/aks-aad)  
[AKS + Azure Firewall](https://github.com/michalswi/aks-with-firewall)


### # **flow**

VNet_1 [ VM ] >> VNet peering >> VNet_2 [ private AKS ]

### # **deployment**

Terraform **v1.0.0**  
azurerm **2.65.0**  

```

az login


## VM

cd vm/

terraform init
terraform plan -out out.plan
terraform apply out.plan


## AKS

cd aks/

terraform init
terraform plan -out out.plan
terraform apply out.plan

```

### # **networking**

More details what I am doing you can find [here](https://docs.microsoft.com/en-us/azure/aks/private-clusters#virtual-network-peering).

```
# check avaiable Resource Groups

az group list --output table
Name               Location    Status
-----------------  ----------  ---------
vmrg               westeurope  Succeeded
mk8srg             westeurope  Succeeded
mk8s-k8s           westeurope  Succeeded        << 'node_resource_group' in 'cluster.tf'



# get VNet IDs

> for 'mk8s-vnet'
K8SVNETID=$(az network vnet show -g mk8srg -n mk8s-vnet --query id --out tsv)

> for 'msvm-vnet'
VMVNETID=$(az network vnet show -g vmrg -n msvm-vnet --query id --out tsv)


# private DNS zone - create virtual network link

DNSZONE=$(az network private-dns zone list -g mk8s-k8s --query "[].{name:name}" --out tsv)

echo $DNSZONE
12056647-25c9-41b4-8632-c2f912d8ca3e.privatelink.westeurope.azmk8s.io

az network private-dns link vnet create \
  -g mk8s-k8s \
  -n aks-vm-dns-link \
  -v $VMVNETID \
  -z $DNSZONE \
  -e False


# add virtual network peering

> aks >> vm

az network vnet peering create \
  --name aks-vm-peer \
  --resource-group mk8srg \
  --vnet-name mk8s-vnet \
  --remote-vnet $VMVNETID \
  --allow-vnet-access

> vm >> aks

az network vnet peering create \
  --name vm-aks-peer \
  --resource-group vmrg \
  --vnet-name msvm-vnet \
  --remote-vnet $K8SVNETID \
  --allow-vnet-access

```
It takes a few minutes for the DNS zone link to become available.

```
# get kubeconfig

az aks get-credentials --resource-group mk8srg --name mk8s


# ssh to your VM, install kubectl and copy kubeconfig from the step above

ssh -i test -l zbych <vm_public_ip> -vv

kubectl get pods --all-namespaces
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   azure-cni-networkmonitor-2hb6v        1/1     Running   0          37m
kube-system   azure-ip-masq-agent-4hh9j             1/1     Running   0          37m
kube-system   coredns-9d6c6c99b-gtlwr               1/1     Running   0          41m
kube-system   coredns-9d6c6c99b-wcs5s               1/1     Running   0          37m
kube-system   coredns-autoscaler-599949fd86-xwm7r   1/1     Running   0          41m
kube-system   kube-proxy-z5scl                      1/1     Running   0          37m
kube-system   metrics-server-77c8679d7d-kg87v       1/1     Running   1          41m
kube-system   tunnelfront-5795f9cc48-lb4fl          1/1     Running   0          41m
```
If I try to connect to Kubernetes cluster from my workstation it won't work:
```
kubectl get pods
Unable to connect to the server: dial tcp: lookup mk8s-233a926a.12056647-25c9-41b4-8632-c2f912d8ca3e.privatelink.westeurope.azmk8s.io on 127.0.0.53:53: no such host
```