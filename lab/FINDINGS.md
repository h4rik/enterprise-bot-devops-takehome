# Part 4 findings — incomplete

The excerpts below are actual outputs from my recorded session and terminal messages. I have not completed a clean final run: the latest `./scenario.sh verify` in the current shell found no deployed lab workloads and returned 10 failures, while the last recorded run had four failures. I am leaving the remaining reporter/API issue visible rather than claiming the lab is green. The assignment asks for six defects; my debugging also encountered the Job restart-policy validation and the image's nonnumeric user constraint, and I have not reconciled the full set into exactly six independent causes yet.

## Finding 1 — Job restart policy

**Symptom**

```text
Job.batch "migrate" is invalid: spec.template.spec.restartPolicy: Required value: valid values: "OnFailure", "Never"
```

This validation message was returned by `./scenario.sh up` in my terminal.

**Cause** The migration Job had an invalid or missing Pod restart policy. Jobs permit `OnFailure` or `Never`.

**Fix** Set `restartPolicy: Never` in the Job pod template so Job retries remain controlled by `backoffLimit`.

**How I found it** I read the API validation error from the first `scenario.sh up` run and corrected the Job template.

## Finding 2 — numeric non-root identity

**Symptom** (from `kubectl describe pod`):

```text
Error: container has runAsNonRoot and image has non-numeric user (nonroot), cannot verify user is non-root
```

**Cause** The image declares a named user, while Kubernetes cannot prove that name is non-root when only `runAsNonRoot: true` is set.

**Fix** Set the pod security context to UID/GID 65532 while retaining `runAsNonRoot: true` and the other container restrictions.

**How I found it** `kubectl describe pod` showed `CreateContainerConfigError` and the kubelet event above. I applied a numeric identity to the workload pod specs.

## Finding 3 — backend listener port

**Symptom** (from `scenario.sh verify`):

```text
FAIL  backend does not answer on http://backend:8080/healthz
```

**Cause** The application listens on 8081, but the container port/probe target initially used 8080. The Service-facing port is still 8080.

**Fix** Use 8081 for the container port and probes, with the backend Service mapping port 8080 to target port 8081.

**How I found it** I compared the service check with the application's startup log, then checked the Service endpoint and probed the backend from inside the namespace.

## Finding 4 — gateway backend address

**Symptom** The recorded verifier reported:

```text
FAIL  gateway /status does not report backend=ok
```

The later direct request returned:

```json
{"app":"gateway","backend":"ok","backend_url":"http://backend:8080","pod":"gateway-5f85d569f4-666l7","self":"ok","version":"2.0.0"}
```

**Cause** The gateway's configured backend URL did not match the in-namespace backend Service endpoint.

**Fix** Configure `BACKEND_URL` as `http://backend:8080`.

**How I found it** I checked the gateway's `/status` from a temporary pod after verifying backend service connectivity. The direct result proves the gateway/backend path worked at that point, but does not replace the final verifier.

## Finding 5 — metrics resource ceiling

**Symptom** The metrics values were initially 2 CPU requested and 4 CPU limited, while `lab/cluster-state/limits.yaml` sets the namespace maximum CPU limit to 1.

**Cause** The metrics container exceeded the environment's LimitRange, preventing compliant scheduling/admission.

**Fix** Reduce the metrics CPU request and limit to values within the namespace ceiling (currently 50m and 200m).

**How I found it** I compared `metrics.resources` in the values file with the LimitRange in the supplied, unchanged cluster state.

## Finding 6 — worker writable cache

**Symptom** The worker did not become ready while its root filesystem was read-only and the application needed a writable cache path.

**Cause** A read-only root filesystem was enabled without a writable volume mounted at the application's cache directory.

**Fix** Keep the root filesystem read-only and mount an `emptyDir` at `/var/cache/app` for transient cache writes.

**How I found it** I inspected the worker pod events and chart volume configuration, then added the writable mount instead of disabling the read-only root filesystem.

## Remaining reporter issue

The reporter ServiceAccount can now list pods according to `kubectl auth can-i`, and its RoleBinding names `reporter`. However, the reporter's application log still showed:

```text
pod list failed: parse pod list: unexpected end of JSON input
GET /healthz -> 503
```

A temporary curl pod using the same ServiceAccount completed successfully, but its response body has not been included here. The latest full verification available to me is not green. I need the response body and a fresh `scenario.sh up` / `scenario.sh verify` result to finish this diagnosis.
