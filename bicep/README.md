# Overview
This folder contains reusable Bicep modules and main file definitions that form part of Arinco's Azure Done Right solution accelerator. 


## Structure
Bicep templates are categorised into two types:
- **Main templates:** Calls modules to create a 'patterned' deployments (e.g. a Landing Zone, a secure Web App Deployment etc.) - generally contains business or infra logic
- **Module templates:** Base level building block templates, commonly associated to a specific resource type (e.g. a VM, an App Service, etc.) - should contain minimal logic
- **Deploy templates:** An environment or instance specific wrapper around a main template so that you can define (or calculate) variable values instead of providing JSON parameter files - should contain no logic
## Modules
A good module should have the following characteristics:
- Focuses on deploying a specific resource type (e.g. a storage account)
- Definitive in properties that are considered best practice (e.g. enforce HTTPs)
- Parameterises all common configurable properties (e.g. sku, type, always on)
  - Define a set of 'mandatory' parameters that require consideration by the consumer (e.g. sku size, access tier, etc.)
  - Define a set of 'optional' parameters by setting default values that don't need consideration by the common consumer, but something that may be changed by an advanced user (e.g. client affinity, soft-delete retention periods)
  - Object and array parameters should contain the metadata decorator detailing the definition
  - Ensures that  `Tags` are a parameter
  - Ensures that `Location` is a parameter, with a default value of `resourcegroup().location`
- Includes a `cannot delete` resource lock definition, with conditional deployment defined by parameter `enableResourceLock`
- Includes a `diagnostics` definition, with conditional deployment defined by parameters for `log analytics` or `storage account` locations
- A `README.md` file to demonstrate the use of the bicep template.  

### File and Folder Structure
- Create a folder for each resource type (e.g. keyvault)
- Create a parent folder if there are multiple iterations of a resource type (e.g. storage-datalake vs storage-queue) or to collate similar categories of resources (e.g. networking)
- Create additional files into the resource folder for 'additive' features, such as Private EndPoint

| Filename | Content|
|-|-|
| *descriptive name*.bicep  | Contains the resource creation logic.  e.g. storage.bicep.  
| *descriptive name*-PE.bicep  | Contains the Private Endpoint specific for that resource type.  e.g. keyvault-PE.bicep.  
| *README*.md  | Contains documentation that describes the module and provides examples that demonstrate the use of the bicep template.    
## Main
A good main definition should have the following characteristics:
- Focuses on deploying a set of resources (via module or other main references) for a defined workload or pattern deployment (e.g. a secure web app backed by SQL database via Private Endpoints)
- Will often have logic built into the main file to help abstract the consumption of sub-modules
- Uses parameters to allow the same main file to be used over multiple environments or instances
  - At a minimum it will proxy all 'mandatory' parameters from sub modules up into the top level that it has not calculated within the main file 
    - You may consider generating the sub-module resource names in the main file based on its own parameters (e.g. for a given customer or workload name and environment, generate the corresponding azure resource names for sub-modules)
  - Ensures that  `Tags` are set for all sub modules (again, expectation is that you generate the tags based on main file parameters)
  - Ensures that appropriate `enableResourceLock` parameters for sub-modules are set for production environments

### File and Folder Structure
- Create a folder for each specific purpose/function/pattern (e.g. LandingZone)
- Each folder may contain multiple main templates that you might chain / nest to further modularise your logic (e.g. a root main, that has sub mains)

| Filename | Content|
|-|-|
| *descriptive name*.bicep  | Contains the main creation logic.  e.g. LandingZone.bicep

## Deploy
This is an optional definition.  The idea behind a deploy template is instead of defining environment or instance specific parameter files (e.g. webapp.dev.parameters) which are ugly JSON files, we can use bicep syntax to define variables and then just calling the main as a module reference, feeding each variable to corresponding parameter.
The main benefits for doing it this way are:
- Bicep syntax is just nicer than JSON.
- You can calculate your variables/parameters (e.g. use the `existing` feature to get resource ids or outputs from other modules)
- You can copy/paste the param section of a bicep file, and replace param with var - now you can just assign the values as you see fit, instead of writing a net new parameter file (or using the sample parameters file)
- The deployment task (whether its a script or devops pipeline) is super simple - just deploy the individual file.
Some of the contraints are:
- It works best when your modules, main and deploy templates are all in the same repo, so it's easier to reference each other
- Need consideration of what happens when you compile/build the bicep file that uses secure parameters - especially when they're referenced at a top level

### File and Folder Structure

| Filename | Content|
|-|-|
| *descriptive name*.bicep  | Contains the main creation logic.  e.g. LandingZone.bicep
