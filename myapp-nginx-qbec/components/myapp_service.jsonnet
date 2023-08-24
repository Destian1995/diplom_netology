
local p = import '../params.libsonnet';
local params = p.components.myapp_service;

[
    {
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": "nginx-app",
  },
  "spec": {
    "type": "NodePort",
    "selector": {
      "app.kubernetes.io/name": "nginx-app"
    },
    "ports": [
      {
        "protocol": "TCP",
        "port": 80,
        "targetPort": 80,
        "nodePort": params.nodeport
      }
    ]
  }
}
]
