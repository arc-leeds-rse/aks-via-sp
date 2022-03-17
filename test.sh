#!/bin/bash

. settings

az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME
kubectl get nodes
