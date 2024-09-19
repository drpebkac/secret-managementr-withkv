# Overview

This folder contains Azure DevOps YAML Pipelines for IAC Deployments

## Branching Strategy

As a standard, utilise trunk-based branching strategies with short-lived feature branches.  The sample pipeline demonstrates the following:

- Triggers on `main` branch only
- Use path filtering to scope your pipeline to the relevant main/modules/parameters
- Stage conditions configured such that:
  - Prod must be deployed through `main` branch
  - Prod has a dependency on a `staging` environment (or equivalent)
  - Manual triggers are allowed on all non-production environments. Intent is to use manual triggering to validate your feature branches

Key notes:

- Ensure you put appropriate stage gate approvals in your Azure DevOps Environment (as defined in Deployment Jobs)
- Ensure you put appropriate branch protection, particularly on `main` (i.e. changes only allowed via PR)

## File and Folder Structure

- Create a folder for each pipeline purpose
  - Create the pipeline file as `azure-pipelines.yml` (makes VSCode detect linter easier)
  - These should be fairly basic and use pipeline templates as much as possible
- `Templates` folder is used to host pipeline templates.

## Pipeline Templates

### Build Template (`build-template.yml`)

This is a Azure DevOps stage template.  It is a single stage used to Build and Test Bicep templates.

Performs the following:

- Builds the given Bicep file into an ARM template
- Runs ARM-TTK tests using Marketplace Extension (future plan to replace this with PSRules)
- Publishes Test Results
- Publishes Pipeline Artefact of ARM JSON template file

### Deploy Templates (`deploy-template-xxx.yml`)

These are Azure DevOps stage templates. They are made up of two stages used for Deployment of ARM templates (built from Bicep).

1. Preview_{StageName} - Optional. Performs what-if job for manual review.
2. {StageName} - Performs deployment job. If using Preview Stage, ensure you have approvals configured in Azure DevOps Environment

Supported deployment scopes:

- `-ten` : **Tenant**. For creating Management Group structures
- `-mg` : **Management Group**.  For deploying Azure Policies and RBAC
- `-sub` : **Subscription**.  For deploying Resource Groups and their Resources
- `-rg` : **Resource Group**.  For deploying Resources

Each deployment performs the following:

- Pulls in repository (to get parameter files)
- Pulls in Pipeline artefact from Build stage
- Deploys ARM template in What-If mode (if preview flag set to true)
- Deploys ARM template
