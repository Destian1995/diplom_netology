
local p = import '../params.libsonnet';
local params = p.components.myapp_deployment;

[
    {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "name": "myapp-nginx",
        "labels": {
        "app.kubernetes.io/name": "nginx-app"
        }
    },
    "spec": {
        "replicas": params.replicas,
        "selector": {
        "matchLabels": {
            "app.kubernetes.io/name": "nginx-app"
        }
        },
        "template": {
        "metadata": {
            "labels": {
            "app.kubernetes.io/name": "nginx-app"
            }
        },
        "spec": {
            "containers": [
            {
                "name": "nginx-app",
                "image": params.rep + '/' + params.tag,
                "resources": {
                "requests": {
                    "memory": "24Mi",
                    "cpu": "32m"
                },
                "limits": {
                    "memory": "48Mi",
                    "cpu": "64m"
                }
                },
                "ports": [
                {
                    "containerPort": 80
                }
                ]
            }
            ]
        }
        }
    }
    }
]
