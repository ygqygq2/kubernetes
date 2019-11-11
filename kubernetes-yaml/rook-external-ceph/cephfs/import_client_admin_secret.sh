#!/usr/bin/env bash

export NAMESPACE=rook-ceph
ceph auth get-key client.admin > /etc/ceph/ceph.client.admin.secret

kubectl create secret generic ceph-admin-secret --from-file=/etc/ceph/ceph.client.admin.secret --namespace=$NAMESPACE
