# Bicep Lint Action
GitHub Action to lint [Bicep](https://github.com/Azure/bicep). This will show the linting messages in both the pull requests and the actions workflow runs. You are also able to set your own [Bicep linter configuration](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-config-linter) which this action will respect.

## Input Configuration Options
analyse-all-files
- **Description**: Used to determine whether you just want to analyse the files changed or the whole repository. When set to false on a pull request event, it will compare between the current and target branch. When set to false on a push event, it will compare the changes between two commits.
- **Required**: false
- **Default**: 'false'

## Example Workflow File
```
name: Linter
on:
  pull_request:
  workflow_dispatch:

jobs:
  bicep-linter:
    name: Bicep
    runs-on: ubuntu-latest
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v3
      with:
        # Incremental diffs require fetch depth to be at 0 to grab the target branch
        fetch-depth: '0'
    - name: Run Bicep Linter
      uses: synergy-au/bicep-lint-action@v1
      with:
        analyse-all-files: 'true'
```