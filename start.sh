#!/bin/sh

echo $REGISTRY_USERNAME
echo $REGISTRY_PASSWORD

htpasswd -Bbn $REGISTRY_USERNAME $REGISTRY_PASSWORD > /htpasswd

# 输入config.yaml文件名
config_file="/home/config-auth-server.yml"

# 替换函数，将 ${VAR} 替换为实际值
replace_var() {
  local var_name="$1"
  local var_value="$2"
  sed -i "s|\${$var_name}|$var_value|g" "$config_file"
}

# 使用实际值替换config.yaml文件中的环境变量
PASSWORD=$(awk -F: '{print $2}' /htpasswd)

echo $REGISTRY_USERNAME
echo $PASSWORD

replace_var "USERNAME" "$REGISTRY_USERNAME"
replace_var "PASSWORD" "$PASSWORD"
replace_var "PUBLIC_NAMESPACE" "$PUBLIC_NAMESPACE"


chmod 755 /docker-entrypoint.d/90-docker-registry-ui.sh && \
cd /usr/share/nginx/html/ && /docker-entrypoint.d/90-docker-registry-ui.sh && \
#cp /etc/nginx/conf.d/default.conf /etc/nginx/http.d/default.conf

nginx &
/home/auth-server -logtostderr=true /home/config-auth-server.yml &

if [ $ENABLE_PUBLIC_PULL -eq 1 ]; then
	echo "token"
	export REGISTRY_AUTH='token' \
	REGISTRY_AUTH_TOKEN_REALM="${DOMAIN_URL}/auth" \
	REGISTRY_AUTH_TOKEN_SERVICE='Registry Realm' \
	REGISTRY_AUTH_TOKEN_ISSUER='Acme auth server' \
	REGISTRY_AUTH_TOKEN_ROOTCERTBUNDLE='/home/root-certificate.pem' && \
	registry serve /etc/docker/registry/config.yml
else
	echo "htpasswd"
	export REGISTRY_AUTH='htpasswd' \
	REGISTRY_AUTH_HTPASSWD_PATH="/htpasswd" \
	REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" && \
	registry serve /etc/docker/registry/config.yml
fi

tail -f