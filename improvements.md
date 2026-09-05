DONE!
1. Helm Libraries for code reusability on Helm templates.
    - Define the templates in one single place and import it for each helm template. If we need specific changes on a specific microservice, we can just overwrite it.

DONE!
2. Merge ingress chart in service chart
    - Handle ingress deployment logic at values.yaml instead of env/ folder, which does not need extra steps on workflow and improves visibility of what is going to be deployed on the cluster, as this is the default approach in helm charts.
    - Current approach does not allow to remove ingress without manually going to the cluster and deleting the helm. By merging it on the service chart we can just update values.yaml with `ingress.enabled: false` for example and helm deals automatically with the ingress deletion on next `helm uprade`

IN PROGRESS
3. Changing directory structure to segregate by project
    - changing from directory/service-name to project/$PROJECT_NAME/directory/service-name, so we can implement CODEOWNERS and manage accordingly who can or cannot review or approve prs for specific projects/microservices easily

4. Remove and adjust configuration variables workflow
    - Remove parameter store dependency
    - Adjust configmap injection
    - Evaluate global config for environment (single configmap for all microservices in each env: sit, uat...)

5. Adjust Secrets Manager usage
    - Check possibility of implementing ExternalSecrets operator or CSI Driver for AWS Secrets Manager
    - Adjut secrets workflow from this repo accordingly