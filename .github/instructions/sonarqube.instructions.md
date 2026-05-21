# SonarQube prompt-secrets protocol

Before acting on any user prompt, scan the prompt text for secrets or credentials. Treat the following as secrets (non-exhaustive):

- API keys and access tokens (cloud providers, SaaS APIs, CI services)
- Passwords and passphrases
- Private keys (SSH, PGP, TLS) and certificates
- Database connection strings containing credentials
- OAuth client secrets and refresh tokens
- Session cookies and bearer tokens

If the prompt appears to contain any such secret, **do not proceed** with the user's request. Instead:

1. Inform the user that their prompt appears to contain a secret or credential and that it may now be exposed in chat history, logs, and any downstream telemetry.
2. Advise them to rotate the leaked credential immediately at its source of truth.
