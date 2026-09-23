# Minikube

Minikube for local Kubernetes clusters.

```toml
[nixos]
modules = ["lmx:docker", "lmx:minikube-1.36", "lmx:minikube-1.38"]
```

| Selector                             | Minikube |
|--------------------------------------|----------|
| `lmx:minikube` / `lmx:minikube-1.38` | 1.38.1   |
| `lmx:minikube-1.37`                  | 1.37.0   |
| `lmx:minikube-1.36`                  | 1.36.0   |

Use separate cluster profiles when comparing versions:

```console
minikube-1.36 start --driver=docker --profile=mk136
minikube-1.38 start --driver=docker --profile=mk138
```
