
local p = import '../params.libsonnet';
local params = p.components.myapp_deployment;

[
    {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
        "name": "myapp-nginx",
        "labels": {
        "app.kubernetes.io/name": "myapp-nginx"
        }
    },
    "spec": {
        "replicas": params.replicas,
        "selector": {
        "matchLabels": {
            "app.kubernetes.io/name": "myapp-nginx"
        }
        },
        "template": {
        "metadata": {
            "labels": {
            "app.kubernetes.io/name": "myapp-nginx"
            }
        },
        "spec": {
            "containers": [
            {
                "name": "myapp-nginx",
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