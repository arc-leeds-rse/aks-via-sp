#!/bin/bash

. settings.sh

# Set it so we're using the teaching subscription
az account set -n $SUB_NAME

OWNER_SP=$(grep appId cluster-owner-sp |awk -F\" '{print $4}')
INTERNAL_SP=$(grep appId cluster-internal-sp |awk -F\" '{print $4}')

az aks delete -g $RG_NAME -n $CLUSTER_NAME -y --no-wait

az ad sp delete --id $OWNER_SP &&
az ad sp delete --id $INTERNAL_SP &&
rm -f cluster-internal-sp cluster-owner-sp
