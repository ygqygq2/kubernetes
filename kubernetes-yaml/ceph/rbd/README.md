
# 1. 将ceph密码环导入kubernetes

## 1.1 导入admin密钥环
```bash
ceph auth get client.admin 2>&1 |grep "key = " |awk '{print  $3'} |xargs echo -n > /tmp/secret
kubectl create secret generic ceph-admin-secret --from-file=/tmp/secret --namespace=kube-system
```

## 1.2 创建Ceph pool 和user secret
```bash
ceph osd pool create kube 128 128
ceph auth add client.kube mon 'allow r' osd 'allow rwx pool=kube'
ceph auth get-key client.kube > /tmp/kube.secret
kubectl create secret generic ceph-secret --from-file=/tmp/kube.secret --namespace=kube-system
```