.
├── README.md
├── branches
├── config.yaml
├── env #contains environment specific values on config.yaml like aws arns, kubernetes cluster names, etc.
│   └── example-service1
│       ├── preprod
│       │   └── config.yaml
│       ├── prod
│       │   └── config.yaml
│       ├── sit
│       │   └── config.yaml
│       └── uat
│           └── config.yaml
├── helm #helm templates for each service
│   └── example-service1
│       └── service
│           ├── Chart.yaml
│           └── templates
│               ├── configmap.yaml
│               ├── deployment.yaml
│               ├── ingress.yaml
│               ├── secret.yaml
│               ├── service.yaml
│               ├── ssl-secret.yaml
│               └── tls-secret.yaml
├── helm-microservice-library #helm library charts for common resources across microservices
│   ├── cciam
│   │   ├── Chart.yaml
│   │   └── templates
│   │       ├── _configmap.yaml
│   │       ├── _deployment.yaml
│   │       ├── _ingress.yaml
│   │       ├── _secret.yaml
│   │       ├── _service.yaml
│   │       ├── _ssl-secret.yaml
│   │       └── _tls-secret.yaml
│   └── mib
│       ├── Chart.yaml
│       └── templates
│           ├── _configmap.yaml
│           ├── _deployment.yaml
│           ├── _ingress.yaml
│           ├── _secret.yaml
│           ├── _service.yaml
│           ├── _ssl-secret.yaml
│           └── _tls-secret.yaml
├── secrets # config.yml file contains credentials to be stored on aws secrets manager only for each environment
│   └── example-service1
│       ├── preprod
│       │   └── config.yml
│       ├── prod
│       │   └── config.yml
│       ├── sit
│       │   └── config.yml
│       └── uat
│           └── config.yml
├── ssl-cert #contains ssl certificates for each service and environment which is used for mtls
│   └── example-service1
│       ├── preprod
│       │   └── ROOTCA.crt
│       ├── prod
│       │   └── ROOTCA.crt
│       ├── sit
│       │   └── ROOTCA.crt
│       └── uat
│           └── ROOTCA.crt
└── values # actual helm values for each service and environment
    └── example-service1
        ├── preprod
        │   ├── ingress
        │   │   └── values.yaml
        │   └── service
        │       └── values.yaml
        ├── prod
        │   ├── ingress
        │   │   └── values.yaml
        │   └── service
        │       └── values.yaml
        ├── sit
        │   ├── ingress
        │   │   └── values.yaml
        │   └── service
        │       └── values.yaml
        └── uat
            ├── ingress
            │   └── values.yaml
            └── service
                └── values.yaml