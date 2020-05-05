#!/bin/bash
echo "Setting environment variables for Terraform"
export ARM_SUBSCRIPTION_ID=<your-subscription-id>
export ARM_CLIENT_ID=<your-sp-app-id>
export ARM_CLIENT_SECRET=<your-sp-password>
export ARM_TENANT_ID=<your-tenant-id>

# Not needed for public, required for usgovernment, german, china
export ARM_ENVIRONMENT=public