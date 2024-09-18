TOKEN=${TF_GITHUB_ACTION_TOKEN}
echo "the token ${TF_GITHUB_ACTION_TOKEN}"
curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @payload.json \
  https://app.terraform.io/api/v2/organizations/vti-practices-tf/authentication-token
