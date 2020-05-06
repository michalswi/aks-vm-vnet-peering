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

Terraform **v0.12.20**  

```

## subscription

$ export TF_VAR_client_id=<> && \
export TF_VAR_client_secret=<>


## VM

$ cd vm/

$ terraform init
$ terraform plan -out out.plan

$ terraform apply out.plan
(...)
Outputs:
public_ip_address = <your_VM_public_ip>


## AKS

$ cd aks/

$ terraform init
$ terraform plan -out out.plan

$ terraform apply out.plan

```

### # **networking**

More details what I am doing here you can find [here](https://docs.microsoft.com/en-us/azure/aks/private-clusters#virtual-network-peering).

```

# check avaiable Resource Groups

$ az group list --output table
Name                       Location    Status
-------------------------  ----------  ---------
mk8srg                     westeurope  Succeeded
MC_mk8srg_mk8s_westeurope  westeurope  Succeeded
vmrg                       westeurope  Succeeded


# get VNet IDs

> for 'mk8s-vnet'
$ K8SVNETID=$(az network vnet show -g mk8srg -n mk8s-vnet --query id --out tsv)
$ echo $K8SVNETID
/subscriptions/8c3e0cf6-a66d-4023-9e46-883f37edabff/resourceGroups/mk8srg/providers/Microsoft.Network/virtualNetworks/mk8s-vnet

> for 'msvm-vnet'
$ VMVNETID=$(az network vnet show -g vmrg -n msvm-vnet --query id --out tsv)


# private DNS zone - create virtual network link

$ DNSZONE=$(az network private-dns zone list -g MC_mk8srg_mk8s_westeurope --query "[].{name:name}" --out tsv)
$ echo $DNSZONE
f4cb5c2f-8656-4c51-8c76-fd2b75c69f8b.privatelink.westeurope.azmk8s.io

$ az network private-dns link vnet create \
  -g MC_mk8srg_mk8s_westeurope \
  -n aks-vm-dns-link \
  -v $VMVNETID \
  -z $DNSZONE \
  -e False


# add virtual network peering

> peering vnets: aks >> vm
$ az network vnet peering create \
  --name aks-vm-peer \
  --resource-group mk8srg \
  --vnet-name mk8s-vnet \
  --remote-vnet $VMVNETID \
  --allow-vnet-access
  
> peering vnets: vm >> aks
$ az network vnet peering create \
  --name vm-aks-peer \
  --resource-group vmrg \
  --vnet-name msvm-vnet \
  --remote-vnet $K8SVNETID \
  --allow-vnet-access

```
It takes a few minutes for the DNS zone link to become available. Once configuration is done, ssh to your VM (user+pass in `vm/vm.tf`). 

```

# get kubeconfig first

$ az aks get-credentials --resource-group mk8srg --name mk8s


# ssh to your VM, install kubectl and copy kubeconfig from the step above

zbyszek@azuretest:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   azure-cni-networkmonitor-jrbqk        1/1     Running   0          31m
kube-system   azure-ip-masq-agent-zv2zp             1/1     Running   0          31m
kube-system   coredns-698c77c5d7-jcbmr              1/1     Running   0          37m
kube-system   coredns-698c77c5d7-kvj6q              1/1     Running   0          30m
kube-system   coredns-autoscaler-79b778686c-5b5rp   1/1     Running   0          37m
kube-system   kube-proxy-cfj52                      1/1     Running   0          30m
kube-system   metrics-server-7d654ddc8b-nhmfh       1/1     Running   1          37m
kube-system   tunnelfront-57d65fb8c7-thggh          1/1     Running   0          37m
```