# Part 5 — Written question

I would first inventory the 40 Ingress objects, controller settings, annotations, TLS secrets, rewrite rules, auth, timeouts, and traffic patterns. I would map each feature to the Gateway API implementation we plan to run and identify unsupported annotations before changing traffic.

Next, I would install the Gateway API CRDs and controller alongside ingress-nginx, then establish GatewayClass, Gateway, certificates, DNS, and observability. I would migrate a low-risk Ingress first, keeping the old route available. I would compare responses, status codes, latency, TLS behavior, and logs, then move services in small batches. DNS or weighted routing would shift traffic gradually, with a tested rollback to the old controller at each stage.

I expect annotation behavior to break first: rewrites, authentication, rate limits, custom snippets, timeouts, and header handling differ across controllers and may need extension policies or application changes. TLS references, listener hostnames, route attachment permissions, and cross-namespace references can also fail validation. I would monitor rejected routes and controller events rather than assume that accepted YAML means working traffic.

After all routes are stable, I would remove old Ingress resources and ingress-nginx only after observing a full business cycle and confirming no hidden DNS or certificate dependencies. I would document unsupported features, owners, and rollback steps throughout the migration.
