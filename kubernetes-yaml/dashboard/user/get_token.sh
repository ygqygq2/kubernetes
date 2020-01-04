namespace=$1
user=$2

[ -z $user ] && exit 1

cd `dirname $0`
pwd_path=$(pwd)

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
