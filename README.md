# Private AKS cluster

By default AKS cluster is created using a public IP for the kubernetes API server. Once **private cluster** is enabled **only** machines (in this example single VM) connected to AKS VNet has access/can connect to the API Server.  

What we have here is single VM and AKS deployed in separate Virtual Networks (VNets) using Virtual Network Peering.

Official Azure documentation is available [here](https://docs.microsoft.com/en-us/azure/aks/private-clusters).

Similar topics related to access to AKS:  
[AKS + Azure Active Directory](https://github.com/michalswi/aks-aad)  
[AKS + Azure Firewall](https://github.com/michalswi/aks-with-firewall)


### \# **Architecture**

VNet_1 [ VM ] >> VNet peering >> VNet_2 [ private AKS ]


### \# **Deployment**

Terraform **v1.0.11**  
azurerm **2.87.0**  

```
## VM

az login

cd vm/

terraform init
terraform plan -out out.plan
terraform apply out.plan


## AKS

cd aks/

export TF_VAR_client_id=<> && \
export TF_VAR_client_secret=<>

terraform init
terraform plan -out out.plan
terraform apply out.plan

```

### \# **Networking**

More details what I am doing you can find [here](https://docs.microsoft.com/en-us/azure/aks/private-clusters#virtual-network-peering).

```
# check available Resource Groups

$ az group list --output table
Name                    Location    Status
----------------------  ----------  ---------
demo-rg                 westeurope  Succeeded     << VM RG
demo-private-rg         westeurope  Succeeded     << K8s RG
demo-nrg                westeurope  Succeeded     << 'node_resource_group' in 'aks/main.tf'


# get VNet IDs

K8SVNETID=$(az network vnet show -g demo-private-rg -n demo-vnet --query id --out tsv) &&\
VMVNETID=$(az network vnet show -g demo-rg -n demo-vnet --query id --out tsv)


# private DNS zone - create virtual network link

DNSZONE=$(az network private-dns zone list -g demo-nrg --query "[].{name:name}" --out tsv)

az network private-dns link vnet create \
-g  demo-nrg \
-n aks-vm-dns-link \
-v $VMVNETID \
-z $DNSZONE \
-e False


# add virtual network peering

> aks >> vm

az network vnet peering create \
--name aks-vm-peer \
--resource-group demo-private-rg \
--vnet-name demo-vnet \
--remote-vnet $VMVNETID \
--allow-vnet-access

> vm >> aks

az network vnet peering create \
--name vm-aks-peer \
--resource-group demo-rg \
--vnet-name demo-vnet \
--remote-vnet $K8SVNETID \
--allow-vnet-access
```

It takes a few minutes for the DNS zone link to become available.

```
# Get kubeconfig

az aks get-credentials --resource-group demo-private-rg --name demo-k8s


# SSH to your VM, install kubectl and copy paste kubeconfig from the step above

$ ssh -i test -l admin <vm_public_ip> -vv

$ > install kubectl

$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   azure-cni-networkmonitor-lhp8j        1/1     Running   0          16m
kube-system   azure-ip-masq-agent-4sft5             1/1     Running   0          16m
kube-system   coredns-84d976c568-bckll              1/1     Running   0          20m
kube-system   coredns-84d976c568-tftcc              1/1     Running   0          16m
kube-system   coredns-autoscaler-54d55c8b75-8xp62   1/1     Running   0          20m
kube-system   kube-proxy-sfd9f                      1/1     Running   0          16m
kube-system   metrics-server-569f6547dd-jds9j       1/1     Running   0          20m
kube-system   tunnelfront-db8c4c655-8v25c           1/1     Running   0          20m
```

If I try to connect to Kubernetes cluster from my workstation it won't work:
```
$ kubectl get pods
Unable to connect to the server: dial tcp: lookup mk8s-6ea3408c.46b55328-751c-471a-bbeb-51fd47654d45.privatelink.westeurope.azmk8s.io on 127.0.0.53:53: no such host
```