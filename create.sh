#!/bin/bash

# The settings file contains the settings that need to be changed
. settings

# Bail out if anything breaks, and be nice and verbose
set -ex

# Set it so we're using the teaching subscription
az account set -n $SUB_NAME

# Pull out these variables from the az cli
TENANT=$(az account show | jq -r .tenantId)
SUBSCRIPTION=$(az account show | jq -r .id)

# Make the two service principals (credentials), one for use by the cluster
# owner (us), and one for internal kubernetes purposes
az ad sp create-for-rbac > cluster-owner-sp
az ad sp create-for-rbac > cluster-internal-sp

# Pull these variables out from the saved credential files
OWNER_SP=$(jq -r .appId cluster-owner-sp)
OWNER_PASS=$(jq -r .password cluster-owner-sp)
INTERNAL_SP=$(jq -r .appId cluster-internal-sp)
INTERNAL_PASS=$(jq -r .password cluster-internal-sp)

az role assignment create --assignee "$OWNER_SP" --scope "/subscriptions/${SUBSCRIPTION}/resourceGroups/${RG_NAME}" --role "AKS Compute Mgr"

# Save our config
mv ~/.azure ~/.azure.bak

# Login with this account
until az login --service-principal --username "$OWNER_SP" --password "$OWNER_PASS" --tenant "$TENANT"
do
  echo Retrying login
  sleep 5
done

az aks create -g $RG_NAME -n $CLUSTER_NAME --service-principal "$INTERNAL_SP" --client-secret "$INTERNAL_PASS" --node-vm-size $VM_SIZE --node-count $VM_COUNT --generate-ssh-keys

# Put our config back
rm -rf ~/.azure
mv ~/.azure.bak ~/.azure
