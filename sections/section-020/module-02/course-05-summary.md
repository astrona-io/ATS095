# Summary

A private registry needs a sign-in, may need a private certificate, and gives you a way to check who built a release.

## What you learned

A registry that requires authentication answers 401 with a `WWW-Authenticate` header. `flux create secret oci` writes a `kubernetes.io/dockerconfigjson` Secret for one registry address, and `spec.secretRef` of the `OCIRepository` names it in the same namespace. The address in the Secret and in the `url` must match. A missing Secret and a wrong password both end in the condition `FetchFailed` with the reason `AuthenticationFailed`, so check the Secret as well as the field.

`spec.serviceAccountName` shares one pull secret through `imagePullSecrets`. `spec.provider` selects the cloud token flow for `aws`, `azure` and `gcp`, and the default `generic` uses a Secret. `certSecretRef` adds a private CA with `ca.crt`, and a client certificate with `tls.crt` and `tls.key`. `proxySecretRef` holds the key `address`, with `username` and `password` if needed. `insecure` allows plain HTTP and is not a fix for certificate errors.

`spec.verify` checks a cosign or notation signature before the artifact is stored. A failed check sets `SourceVerified` to `False` with the reason `VerificationError`, and the artifact is not stored. Keyless signing uses `matchOIDCIdentity` with anchored expressions. The key facts to remember are these:

- 401 means the registry wants credentials; it is not a network fault.
- The Secret lives in the namespace of the source.
- Add the CA with `certSecretRef`, never `insecure`, for a certificate error.
- A signature belongs to a digest, and an unverified artifact is never stored.

<!-- astrona:playground:destroy -->
