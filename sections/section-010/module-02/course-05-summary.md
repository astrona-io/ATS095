# Summary

A `GitRepository` connects to a Git server through its URL, a few fields of `spec` and the keys of one Secret. When the connection fails, the message is in the `Ready` condition, and it points at one of those places.

## What you learned

For HTTPS, source-controller checks the certificate of the server against the CAs it knows. A private CA goes into the key `ca.crt` of the Secret, and a client certificate for mutual TLS into `tls.crt` and `tls.key`. The Secret must be in the namespace of the `GitRepository`, and there is no field to turn the check off.

A proxy for one source goes into a Secret with the key `address` (and optionally `username` and `password`) named in `spec.proxySecretRef`. It applies to HTTP and HTTPS URLs and wins over the proxy environment variables of the controller. `spec.timeout` bounds one fetch and defaults to `60s`.

Credentials depend on the host. Basic authentication uses `username` and `password`, and hosted services expect a personal access token in the password field. A bearer token uses the key `bearerToken`. A GitHub App uses `spec.provider: github` and the keys `githubAppID` or `githubAppClientID`, `githubAppInstallationOwner` or `githubAppInstallationID`, and `githubAppPrivateKey`. Azure DevOps can use `spec.provider: azure` with a service account that has a workload identity.

Over SSH, the Secret holds `identity` and `known_hosts`. An entry for a server on a port other than 22 is written `[host]:port`. A changed host key is a reason to scan and verify, never to remove the check. The key facts to remember are these:

- TLS keys are `ca.crt`, `tls.crt` and `tls.key`.
- The proxy Secret needs `address`.
- A token goes where a password goes, except a bearer token.
- A wrong port or a wrong host key both stop an SSH fetch, and the condition tells which.

<!-- astrona:playground:destroy -->
