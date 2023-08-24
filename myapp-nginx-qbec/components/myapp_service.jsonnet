
local p = import '../params.libsonnet';
local params = p.components.myapp_service;

[
    {
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": "myapp-nginx",
  },
  "spec": {
    "type": "NodePort",
    "selector": {
      "app.kubernetes.io/name": "myapp-nginx"
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