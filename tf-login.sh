TOKEN=pBOo72nLzYQHUw.atlasv1.Io1OILrbq2GHi4xiazeCjHs1cgJ1O4gsn9FwLzca4QaJlPIaC5y6cxdCeWBQtdRla6c
curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @payload.json \
  https://app.terraform.io/api/v2/organizations/vti-practices-tf/authentication-token
