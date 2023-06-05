# HOW TO USE
## Master node
bash master.sh [pod-network-cidr]
Ex: `bash master.sh 192.168.0.0/24`
## Woker node
bash node.sh
## Requirement
* Run on VM with at least 2 core and 4G RAM or run kubeadm init with options `--ignore-preflight-errors=NumCPU`
