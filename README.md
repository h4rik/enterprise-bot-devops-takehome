# Enterprise Bot DevOps take-home

This repository contains the Python service and Docker image (Part 1), Helm chart (Part 2), local setup script (Part 3), and the debug lab (Part 4).

## Run and verify

Requirements: Docker, kind, kubectl, and Helm.

```bash
./setup.sh
kubectl --context kind-demo -n demo get pods,svc,ingress
kubectl --context kind-demo -n demo port-forward svc/demo 8080:5000
```

In another terminal, check `http://localhost:8080/` and `http://localhost:8080/healthz`. The root endpoint should return the configured app name, version, and pod hostname.

Run the debug lab with `cd lab && ./scenario.sh up && ./scenario.sh verify`.

## Resource choices

The service chart requests 100m CPU and 128Mi memory, with limits of 200m CPU and 256Mi memory. These are modest starting values for a small Flask service; production values should come from measured usage and load testing.

## Scope and production follow-up

I kept this as a local kind exercise. I did not add CI, image vulnerability scanning, application metrics, or production ingress TLS. For production I would add automated build/lint/scan gates, immutable image digests, secret management, TLS, structured logs/metrics/traces, and resource values based on observed load. The omitted CI and security scans mean regressions and vulnerable dependencies are not caught automatically.

## Part 4 status

The recorded session and fixed chart are included. A gateway request returned `{"app":"gateway","backend":"ok","backend_url":"http://backend:8080",...}`. However, the latest `scenario.sh verify` run available during preparation did not pass: in the active context the lab workloads were absent, and the earlier recorded run still reported reporter and service checks failing. I have not verified a clean, all-green Part 4 run, so this submission should be treated as incomplete until `./scenario.sh up` followed by `./scenario.sh verify` passes in the grading environment.

## How I used AI

I used ChatGPT as a coding and debugging assistant across Parts 1–4. I asked it to review the Python service and Dockerfile, explain and correct the Helm templates and setup script, interpret Kubernetes pod events and logs, and suggest diagnostic commands for the lab. It also helped me understand port and probe mismatches, non-root image identity, resource limits, writable volumes, and ServiceAccount RBAC. I ran commands against my own local Docker/kind setup and used those outputs to make and check changes. The debugging conversation included wrong turns: for example, BusyBox `wget` produced a TLS error against the Kubernetes API, so I switched to a curl image with the projected CA. The final full Part 4 verification is still outstanding, and I need to be able to explain each change in a live walkthrough.
