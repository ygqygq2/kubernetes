
# 1. 将ceph密码环导入kubernetes

cephfs和rbd只需要导入一次

## 1.1 导入admin密钥环
```bash
ceph auth get client.admin 2>&1 |grep "key = " |awk '{print  $3'} |xargs echo -n > /tmp/secret
kubectl create secret generic ceph-admin-secret --from-file=/tmp/secret --namespace=kube-system
```

# 2. 创建cephfs
creatring pools

```
[root@ceph-1 ceph]# ceph osd pool create cephfs_data 64
pool 'cephfs_data' created
[root@ceph-1 ceph]# ceph osd pool create cephfs_metadata 64
pool 'cephfs_metadata' created
```

creating a filesystem

```
[root@ceph-1 ceph]# ceph fs new cephfs cephfs_metadata cephfs_data
new fs with metadata pool 2 and data pool 1
[root@ceph-1 ceph]# ceph fs ls
name: cephfs, metadata pool: cephfs_metadata, data pools: [cephfs_data ]
```

一旦文件系统创建好之后，mds的状态就会发生变化，如下所示：

```
[root@ceph-1 ceph]# ceph mds stat
cephfs-1/1/1 up  {0=ceph-2=up:active}, 2 up:standby
```

