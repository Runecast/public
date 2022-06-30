#!/bin/bash

#use suitable AWS region
export AWS_REGION=eu-central-1

#update these values to your needs
rca_name=rca.example.local
pool_name=cognito-oidc-test
client_name=oidc-client
domain_prefix=pool-domain
group_name=admins
user_name=testuser
user_email=testuser@example.local
user_password='Runecast!1'

#create user pool
userPoolId=$(aws cognito-idp create-user-pool \
    --pool-name "${pool_name}" \
    --auto-verified-attributes email | jq -r '.UserPool.Id')

#create user pool client
clientOutput=$(aws cognito-idp create-user-pool-client \
    --user-pool-id "${userPoolId}" \
    --client-name "${client_name}" \
    --callback-urls "https://${rca_name}/rc2/login/oauth2/code/cognito-idp.${AWS_REGION}.amazonaws.com" \
    --allowed-o-auth-flows code \
    --allowed-o-auth-scopes openid \
    --allowed-o-auth-flows-user-pool-client \
    --generate-secret \
    --supported-identity-providers COGNITO)
clientId=$(echo $clientOutput | jq -r '.UserPoolClient.ClientId')
clientSecret=$(echo $clientOutput | jq -r '.UserPoolClient.ClientSecret')

#create domain
aws cognito-idp create-user-pool-domain --user-pool-id $userPoolId --domain "${domain_prefix}-${clientId:0:5}"

#create group
aws cognito-idp create-group --user-pool-id $userPoolId --group-name "${group_name}" >/dev/null

#create user
aws cognito-idp admin-create-user --user-pool-id $userPoolId \
    --username "${user_name}" \
    --message-action SUPPRESS \
    --user-attributes "Name=email,Value=${user_email}" >/dev/null

#set user password
aws cognito-idp admin-set-user-password --user-pool-id $userPoolId \
    --username "${user_name}" \
    --password "${user_password}"

#add user to group
aws cognito-idp admin-add-user-to-group --user-pool-id $userPoolId --username "${user_name}" --group-name "${group_name}"

echo "Configure Runecast Single Sign-on using details:"
printf "%-30s %s\n" "Issuer location:" "https://cognito-idp.${AWS_REGION}.amazonaws.com/${userPoolId}"
printf "%-30s %s\n" "Client ID:" ${clientId}
printf "%-30s %s\n" "Client Secret:" ${clientSecret}
printf "%-30s %s\n" "Client name:" "Cognito"
printf "%-30s %s\n" "Additional Scope (Optional):" "{Keep empty}"
printf "%-30s %s\n" "Roles Key:" "cognito:groups"
printf "%-30s %s\n" "Name Key(Optional):" "cognito:username"
printf "%-30s %s\n" "Domain Groups:" "${group_name}"

