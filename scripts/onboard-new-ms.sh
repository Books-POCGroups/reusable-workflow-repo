#!/bin/bash
ACTION="$1"
DOMAIN="$2"
SERVICE_NAME="$3"
ENVIRONMENT="$4"

usage() {
	echo "Usage: $0 create <domain> <service-name> <environment>"
	echo "       $0 rm <domain> <service-name>"
	exit 1
}

if [ -z "$ACTION" ]; then
	usage
fi

# Set environment-specific variables
case "$ENVIRONMENT" in
	sit)
		AWS_ROLE_ARN='arn:aws:iam::609543642903:role/LZ-SelfService-Runner'
		AWS_EKS_CLUSTER_NAME='mib2-eks-cluster-dev'
		HELM_INGRESS_ENABLED=true
		HELM_INGRESS_HOST='dev1c.mobileapps.adcb.com'
		;;
	uat)
		AWS_ROLE_ARN=''
		AWS_EKS_CLUSTER_NAME=''
		HELM_INGRESS_ENABLED=false
		HELM_INGRESS_HOST=''
		;;
	preprod)
		AWS_ROLE_ARN=''
		AWS_EKS_CLUSTER_NAME=''
		HELM_INGRESS_ENABLED=false
		HELM_INGRESS_HOST=''
		;;
	prod)
		AWS_ROLE_ARN=''
		AWS_EKS_CLUSTER_NAME=''
		HELM_INGRESS_ENABLED=false
		HELM_INGRESS_HOST=''
		;;
	*)
		AWS_ROLE_ARN=''
		AWS_EKS_CLUSTER_NAME=''
		HELM_INGRESS_ENABLED=false
		HELM_INGRESS_HOST=''
		;;
esac

print_indent() {
	# Prints a specified number of blank lines (newlines) for visual separation in script output without needing to manually add multiple echo statements.
	#
	# Arguments:
	#   $1 (int): Number of blank lines to print.
	local count="$1"
	for ((i=0; i<count; i++)); do
		echo
	done
}

create_env_config() {
	# Creates and configures the environment YAML file for a microservice.
	#
	# Arguments:
	#   $1 (string): Domain name (e.g., 'mib')
	#   $2 (string): Service name
	#   $3 (string): Environment (e.g., 'sit', 'uat', 'prod')
	#   $4 (string): AWS IAM Role ARN for the environment
	#   $5 (string): AWS EKS Cluster name for the environment
	#
	# Behavior:
	#   - Creates the target environment directory if it doesn't exist.
	#   - Copies a template config file and replaces placeholders with environment-specific values.
	#   - Prints status and error messages with color to enhance debugging.
	local domain="$1"
	local service_name="$2"
	local environment="$3"
	local aws_role_arn="$4"
	local aws_eks_cluster_name="$5"
	local config_template="env/config-template.yaml"
	local config_target="env/$domain/$service_name/$environment/config.yaml"

	print_indent 1
	echo -e "\033[1;33mStarting creation of env configuration\033[0m"

	echo "Creating env configuration env/$domain/$service_name/$environment"
	mkdir -p "env/$domain/$service_name/$environment"
	if [ ! -f "$config_template" ]; then
		echo -e "\033[1;31m[ERROR] $config_template does not exist. Aborting.\033[0m"
		exit 1
	fi
	echo "Copying $config_template to $config_target"
	cp "$config_template" "$config_target"
	echo "Replacing AWS_ROLE_ARN and AWS_EKS_CLUSTER_NAME in $config_target"
	sed -i "s|AWS_ROLE_ARN|$aws_role_arn|g" "$config_target"
	sed -i "s/AWS_EKS_CLUSTER_NAME/$aws_eks_cluster_name/g" "$config_target"
	if [ $? -ne 0 ]; then
		echo -e "\033[1;31m[ERROR] Failed to update $config_target\033[0m"
		exit 1
	fi
	echo -e "\033[1;32mConfig file $config_target created and updated successfully.\033[0m"
}

create_helm_chart() {
	# Creates a Helm chart directory for the service by copying a template and updating the Chart.yaml.
	#
	# Arguments:
	#   $1 (string): Domain name
	#   $2 (string): Service name
	#
	# Behavior:
	#   - Creates the Helm chart directory for the service.
	#   - Copies all files from the template chart directory.
	#   - Updates Chart.yaml to use the new service name.
	#   - Prints status and error messages with color to enhance debugging.
	local domain="$1"
	local service_name="$2"
	local chart_template="helm/charts/$domain/sample-template"
	local chart_target="helm/charts/$domain/$service_name"

	print_indent 1
	echo -e "\033[1;33mStarting creation of helm chart\033[0m"

	echo "Creating helm chart $chart_target"
	mkdir "$chart_target"
	if [ ! -d "$chart_template" ]; then
		echo -e "\033[1;31m[ERROR] $chart_template does not exist. Aborting.\033[0m"
		exit 1
	fi
	echo "Copying $chart_template to $chart_target"
	cp -r "$chart_template/"* "$chart_target/"
	echo "Updating Chart.yaml with service name $service_name"
	sed -i "s/MS_TEMPLATE/$service_name/g" "$chart_target/Chart.yaml"
	if [ $? -ne 0 ]; then
		echo -e "\033[1;31m[ERROR] Failed to update Chart.yaml in $chart_target\033[0m"
		exit 1
	fi
	echo -e "\033[1;32mHelm chart $chart_target created and updated successfully.\033[0m"
}

create_secrets() {
	# Creates the secrets directory and config file for the service and environment.
	#
	# Arguments:
	#   $1 (string): Domain name
	#   $2 (string): Service name
	#   $3 (string): Environment
	#
	# Behavior:
	#   - Creates the secrets directory for the service/environment.
	#   - Copies a secrets template file to the new directory.
	#   - Prints status and error messages with color to enhance debugging.
	local domain="$1"
	local service_name="$2"
	local environment="$3"
	local secrets_dir="secrets/$domain/$service_name/$environment"
	local secrets_template="secrets/config-template.yml"

	print_indent 1
	echo -e "\033[1;33mStarting creation of service's secrets\033[0m"

	if [ ! -f "$secrets_template" ]; then
		echo -e "\033[1;31m[ERROR] $secrets_template does not exist. Aborting.\033[0m"
		exit 1
	fi

	echo "Creating secrets directory $secrets_dir"
	mkdir -p "$secrets_dir"

	if [ ! -d "$secrets_dir" ]; then
		echo -e "\033[1;31m[ERROR] Failed to create directory $secrets_dir\033[0m"
		exit 1
	fi

	cp "$secrets_template" "$secrets_dir/config.yml"
	echo -e "\033[1;32mSecrets directory $secrets_dir created successfully.\033[0m"
}

create_ssl_cert_dir() {
	# Creates the SSL certificate directory for the service and environment, and copies default certs.
	#
	# Arguments:
	#   $1 (string): Domain name
	#   $2 (string): Service name
	#   $3 (string): Environment
	#
	# Behavior:
	#   - Creates the SSL certificate directory for the service/environment.
	#   - Copies default certificates into the directory.
	#   - Prints status and error messages with color to enhance debugging.
	
	local domain="$1"
	local service_name="$2"
	local environment="$3"
	local ssl_cert_dir="ssl-cert/$domain/$service_name/$environment"
	
	print_indent 1
	echo -e "\033[1;33mStarting creation of SSL certificate directory\033[0m"
	
	echo "Creating SSL certificate directory $ssl_cert_dir"
	mkdir -p "$ssl_cert_dir"
	if [ ! -d "$ssl_cert_dir" ]; then
		echo -e "\033[1;31m[ERROR] Failed to create directory $ssl_cert_dir\033[0m"
		exit 1
	fi

	touch "$ssl_cert_dir/.gitkeep"

	echo -e "\033[1;32mSSL certificate directory $ssl_cert_dir created successfully.\033[0m"
}

create_helm_values() {
	# Creates and configures the Helm values.yaml file for the service and environment.
	#
	# Arguments:
	#   $1 (string): Domain name
	#   $2 (string): Service name
	#   $3 (string): Environment
	#
	# Behavior:
	#   - Creates the values directory for the service/environment.
	#   - Copies a values template file to the new directory.
	#   - Replaces placeholders in the values file with environment-specific values.
	#   - Prints status and error messages with color to enhance debugging.
	local domain="$1"
	local service_name="$2"
	local environment="$3"
	local values_template="values/$domain/values-template.yaml"
	local values_target="values/$domain/$service_name/$environment/values.yaml"

	print_indent 1
	echo -e "\033[1;33mStarting creation of Helm Values \033[0m"

	if [ ! -f "$values_template" ]; then
		echo -e "\033[1;31m[ERROR] $values_template does not exist. Aborting.\033[0m"
		exit 1
	fi

	echo "Creating helm values file $values_target"
	mkdir -p "values/$domain/$service_name/$environment"
	if [ ! -d "values/$domain/$service_name/$environment" ]; then
		echo -e "\033[1;31m[ERROR] Failed to create directory values/$domain/$service_name/$environment\033[0m"
		exit 1
	fi

	echo "Copying $values_template to $values_target"
	cp "$values_template" "$values_target"

	echo "Replacing HELM_SERVICE_NAME, HELM_INGRESS_ENABLED, and HELM_INGRESS_HOST in $values_target"
	sed -i "s/HELM_SERVICE_NAME/$service_name/g" "$values_target"
	sed -i "s/HELM_INGRESS_ENABLED/$HELM_INGRESS_ENABLED/g" "$values_target"
	sed -i "s/HELM_INGRESS_HOST/$HELM_INGRESS_HOST/g" "$values_target"
	if [ $? -ne 0 ]; then
		echo -e "\033[1;31m[ERROR] Failed to update $values_target\033[0m"
		exit 1
	fi

	echo -e "\033[1;32mHelm values file $values_target created successfully.\033[0m"
}

case "$ACTION" in
	create)
		if [ -z "$SERVICE_NAME" ] || [ -z "$ENVIRONMENT" ]; then
			usage
		fi

		if [ ! -d "env/$DOMAIN" ] || [ ! -d "helm/charts/$DOMAIN" ] || [ ! -d "secrets/$DOMAIN" ] || [ ! -d "values/$DOMAIN" ]; then
			echo -e "\033[1;31m[ERROR] The specified domain does NOT exist or does not have all required directories. Aborting.\033[0m"
			exit 1
		fi

		create_env_config "$DOMAIN" "$SERVICE_NAME" "$ENVIRONMENT" "$AWS_ROLE_ARN" "$AWS_EKS_CLUSTER_NAME"

		create_helm_chart "$DOMAIN" "$SERVICE_NAME"

		create_secrets "$DOMAIN" "$SERVICE_NAME" "$ENVIRONMENT"

		print_indent 1
		
		create_helm_values "$DOMAIN" "$SERVICE_NAME" "$ENVIRONMENT"
		;;
	include-custom-certs)
		if [ -z "$SERVICE_NAME" ] || [ -z "$ENVIRONMENT" ]; then
			usage
		fi

		create_ssl_cert_dir "$DOMAIN" "$SERVICE_NAME" "$ENVIRONMENT"
		
		;;
	rm)
		if [ -z "$SERVICE_NAME" ] || [ -z "$ENVIRONMENT" ]; then
			usage
		fi
		echo "Deleting directory env/$DOMAIN/$SERVICE_NAME"
		rm -rf env/$DOMAIN/$SERVICE_NAME
		echo "Deleting directory helm/charts/$DOMAIN/$SERVICE_NAME"
		rm -rf helm/charts/$DOMAIN/$SERVICE_NAME
		echo "Deleting directory secrets/$DOMAIN/$SERVICE_NAME"
		rm -rf secrets/$DOMAIN/$SERVICE_NAME
		if [ -d "ssl-cert/$DOMAIN/$SERVICE_NAME" ]; then
			echo "Deleting directory ssl-cert/$DOMAIN/$SERVICE_NAME"
			rm -rf ssl-cert/$DOMAIN/$SERVICE_NAME
		fi
		echo "Deleting directory values/$DOMAIN/$SERVICE_NAME"
		rm -rf values/$DOMAIN/$SERVICE_NAME
		;;
	*)
		usage
		;;
esac