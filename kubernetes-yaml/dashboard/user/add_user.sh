
namespace=$1
user=$2

[ -z $user ] && exit 1

cd `dirname $0`
pwd_path=$(pwd)

mkdir -p $pwd_path/${namespace}

cat > ${namespace}/${namespace}-${user}.yaml <<EOF
---
# ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${namespace}-$user
  namespace: ${namespace}

---
# role
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: ${namespace}
  name: role-${namespace}-$user
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "delete", "update", "patch"]
- apiGroups: [""]
  resources: ["pods/portforward", "pods/proxy"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list", "watch", "delete"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["get", "list", "watch", "create"]
- apiGroups: ["extensions", "apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps", "extensions"]
  resources: ["replicasets"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: ["extensions"]
  resources: ["ingresses"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["daemonsets"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["batch"]
  resources: ["jobs"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: ["batch"]
  resources: ["cronjobs"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["replicationcontrollers"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["statefulsets"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["endpoints"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]

---
# role bind
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: role-bind-${namespace}-$user
  namespace: ${namespace}
subjects:
- kind: ServiceAccount
  name: ${namespace}-$user
  namespace: ${namespace}
roleRef:
  kind: Role
  name: role-${namespace}-$user
  apiGroup: rbac.authorization.k8s.io

---
# clusterrole
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: ${namespace}
  name: clusterrole-${namespace}-$user
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
#- apiGroups: [""]
#  resources: ["namespaces"]
#  verbs: ["get", "watch", "list"]
#
---
# clusterrole bind
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: clusterrole-bind-${namespace}-$user
  namespace: ${namespace}
subjects:
- kind: ServiceAccount
  name: ${namespace}-$user
  namespace: ${namespace}
roleRef:
  kind: ClusterRole
  name: clusterrole-${namespace}-$user
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f ${namespace}/${namespace}-${user}.yaml

[ ! -f kubeapps-applications-read.yaml ] && curl  https://raw.githubusercontent.com/kubeapps/kubeapps/master/docs/user/manifests/kubeapps-applications-read.yaml \
  -o kubeapps-applications-read.yaml
kubectl apply -f kubeapps-applications-read.yaml
kubectl create -n $namespace rolebinding ${namespace}-${user}-view \
  --clusterrole=kubeapps-applications-read \
  --serviceaccount $namespace:${namespace}-$user


export KUBEAPPS_NAMESPACE=kubeapps
#kubectl create -n $namespace rolebinding ${namespace}-${user}-edit \
#--clusterrole=edit \
#--serviceaccount ${namespace}:${namespace}-${user}
kubectl create -n $KUBEAPPS_NAMESPACE rolebinding ${namespace}-${user}-kubeapps-repositories-read \
--role=kubeapps-repositories-read \
--serviceaccount $namespace:${namespace}-$user

#token获取：
token=$(kubectl get -n $namespace secret $(kubectl get -n $namespace serviceaccount ${namespace}-${user} \
  -ojsonpath='{.secrets[].name}') -o jsonpath='{.data.token}' | base64 -d)
echo $token > ${namespace}/${user}-token.txt

#生成config

cat > $namespace/${user}-config <<EOF
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://192.168.105.158:8443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    namespace: ${namespace}
    user: ${namespace}-${user}
  name: kubernetes
current-context: kubernetes
kind: Config
preferences: {}
users:
- name: ${namespace}-${user}
  user:
    token: $token
EOF

