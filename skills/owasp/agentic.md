# Agentic AI Security + ASVS 5.0

## Agentic AI Security (OWASP ASI 2026)

When building or reviewing AI agent systems, check for:

| Risk | Description | Mitigation |
|------|-------------|------------|
| ASI01: Goal Hijack | Prompt injection alters agent objectives | Input sanitization, goal boundaries, behavioral monitoring |
| ASI02: Tool Misuse | Tools used in unintended ways | Least privilege, fine-grained permissions, validate I/O |
| ASI03: Identity & Privilege Abuse | Delegated trust, inherited credentials, role chain exploits | Short-lived scoped tokens, identity verification |
| ASI04: Supply Chain | Compromised plugins/MCP servers | Verify signatures, sandbox, allowlist plugins |
| ASI05: Code Execution | Unsafe code generation/execution | Sandbox execution, static analysis, human approval |
| ASI06: Memory Poisoning | Corrupted RAG/context data | Validate stored content, segment by trust level |
| ASI07: Insecure Inter-Agent Comms | Spoofing/intercepting agent-to-agent messages | Authenticate, encrypt, verify message integrity |
| ASI08: Cascading Failures | Errors propagate across systems | Circuit breakers, graceful degradation, isolation |
| ASI09: Human-Agent Trust Exploitation | Over-trust in agents leveraged to manipulate users | Label AI content, user education, verification steps |
| ASI10: Rogue Agents | Compromised agents acting maliciously | Behavior monitoring, kill switches, anomaly detection |

### Agent Security Checklist

- [ ] All agent inputs sanitized and validated
- [ ] Tools operate with minimum required permissions
- [ ] Credentials are short-lived and scoped
- [ ] Third-party plugins verified and sandboxed
- [ ] Code execution happens in isolated environments
- [ ] Agent communications authenticated and encrypted
- [ ] Circuit breakers between agent components
- [ ] Human approval for sensitive operations
- [ ] Behavior monitoring for anomaly detection
- [ ] Kill switch available for agent systems

---

## ASVS 5.0 Key Requirements

### Level 1 — All Applications
- Passwords minimum 12 characters
- Check against breached password lists
- Rate limiting on authentication
- Session tokens 128+ bits entropy
- HTTPS everywhere

### Level 2 — Sensitive Data
All L1 requirements plus:
- MFA for sensitive operations
- Cryptographic key management
- Comprehensive security logging
- Input validation on all parameters

### Level 3 — Critical Systems
All L1/L2 requirements plus:
- Hardware security modules for keys
- Threat modeling documentation
- Advanced monitoring and alerting
- Penetration testing validation
