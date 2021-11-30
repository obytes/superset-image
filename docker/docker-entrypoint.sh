#!/bin/bash
set -eo pipefail

#=================#
#   PRINTING      #
# ENVs Variables  #
#=================#

if [[ -n "$DATABASE_PORT" && -n "$DATABASE_HOST" && -n "$DATABASE_DIALECT" && -n "$DATABASE_DB" && -n "$DATABASE_USER" && -n "$DATABASE_PASSWORD" ]]

then
  echo Exporting DATABASE_URL environment variable
  export SQLALCHEMY_DATABASE_URI="$DATABASE_DIALECT://$DATABASE_USER:$DATABASE_PASSWORD@$DATABASE_HOST:$DATABASE_PORT/$DATABASE_DB"
  echo $SQLALCHEMY_DATABASE_URI

else
  echo "Required ENV Variables are not set"

fi

#=================#
#   SSM           #
# PARAMETER STORE #
#=================#

if [ -n "$COMMON_SSM_PARAMETER_PATH" ]
then
    echo Exporting Parameters from $COMMON_SSM_PARAMETER_PATH
    aws --region $AWS_REGION ssm get-parameters-by-path --path $COMMON_SSM_PARAMETER_PATH --with-decryption --query Parameters | jq -r 'map("\(.Name | sub("'$COMMON_SSM_PARAMETER_PATH'";""))=\(.Value)") | join("\n")' >> /tmp/common_secrets.env
    echo "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" >> /tmp/common_secrets.env
    eval $(cat /tmp/common_secrets.env | sed 's/^/export /' | sudo tee -a /etc/profile.d/common_secrets.sh)
    eval $(cat /tmp/common_secrets.env >> /etc/environment)
fi


#=========#
#   SSM   #
#=========#

# Register instance on SSM
if [ -n "$INSTANCE_NAME" ]; then
    echo Creating Activation Key with AWS SSM
    read -r ACTIVATION_CODE ACTIVATION_ID <<< $(aws ssm create-activation --default-instance-name "${INSTANCE_NAME}" --iam-role "RDTSSMRole" --registration-limit 1 --region ${AWS_DEFAULT_REGION} --tags "Key=Name,Value=${INSTANCE_NAME}" "Key=Type,Value=fargate" --query "join(' ', [ActivationCode, ActivationId])" --output text)
    echo Registering SSM Code
    sudo amazon-ssm-agent -register -code "${ACTIVATION_CODE}" -id "${ACTIVATION_ID}" -region "${AWS_DEFAULT_REGION}" -clear -y
    echo Starting SSM Agent Services
    sudo amazon-ssm-agent 2>&1 &
    export INSTANCE_ID=$(sudo cat /var/lib/amazon/ssm/registration | jq -r .ManagedInstanceID)
    echo $INSTANCE_ID
fi

# Unregister instance from SSM on SIGTERM
term_handler() {
    if [ -n "$INSTANCE_NAME" ]; then
        aws ssm deregister-managed-instance --region ${AWS_DEFAULT_REGION} --instance-id $(sudo cat /var/lib/amazon/ssm/registration | jq -r .ManagedInstanceID)
        echo "SSM instance Unregistered"
        exit 143; # 128 + 15 -- SIGTERM
    fi
}
trap 'term_handler' SIGTERM SIGINT ERR

"$@"