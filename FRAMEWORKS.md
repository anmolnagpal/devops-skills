# Framework Coverage

Generated from `skills/<name>/SKILL.md` frontmatter by `scripts/generate-index.py`. Do not hand-edit.

15 of 18 skills carry framework mappings. Skills without a security-relevant mapping (finops, skill-creator, adr) are intentionally omitted.

## MITRE ATT&CK (Enterprise)

Reference: https://attack.mitre.org/techniques/

| ID / Technique | Skills |
|---|---|
| T1059 | `github-actions`, `owasp` |
| T1070 | `logging`, `observability` |
| T1078 | `github`, `gitops`, `k8s`, `logging`, `owasp` |
| T1078.004 | `ci`, `github-actions`, `tf`, `wrapper-tf` |
| T1110 | `owasp` |
| T1190 | `appsec`, `owasp` |
| T1195 | `appsec`, `ci`, `github`, `gitops` |
| T1195.001 | `appsec` |
| T1195.002 | `github-actions` |
| T1199 | `github` |
| T1485 | `tf-plan` |
| T1525 | `docker`, `gitops` |
| T1530 | `tf`, `wrapper-tf` |
| T1552 | `appsec`, `ci`, `docker`, `k8s`, `owasp`, `tf`, `wrapper-tf` |
| T1552.001 | `appsec`, `ci`, `github` |
| T1552.004 | `github-actions` |
| T1557 | `owasp` |
| T1562.008 | `logging`, `observability` |
| T1578 | `tf-plan` |
| T1580 | `tf`, `wrapper-tf` |
| T1610 | `docker`, `k8s`, `logging` |
| T1611 | `k8s` |
| T1612 | `docker` |
| T1613 | `k8s`, `logging` |

## NIST CSF 2.0

Reference: https://csrc.nist.gov/pubs/cswp/29/the-nist-cybersecurity-framework-20/final

| ID / Technique | Skills |
|---|---|
| DE.AE-02 | `observability` |
| DE.AE-03 | `logging`, `observability` |
| DE.AE-06 | `observability` |
| DE.CM-01 | `logging` |
| DE.CM-09 | `gitops`, `observability`, `tf`, `tf-plan`, `wrapper-tf` |
| GV.SC-07 | `appsec`, `ci`, `github`, `github-actions`, `gitops` |
| ID.AM-08 | `logging` |
| ID.IM-03 | `incident` |
| ID.IM-04 | `deploy` |
| ID.RA-01 | `appsec`, `docker`, `github`, `gitops`, `owasp`, `tf`, `tf-plan`, `wrapper-tf` |
| ID.RA-09 | `ci`, `github-actions` |
| PR.AA-01 | `ci`, `docker`, `github-actions`, `k8s`, `owasp` |
| PR.AA-05 | `ci`, `github`, `github-actions`, `gitops`, `k8s`, `owasp`, `tf`, `wrapper-tf` |
| PR.DS-01 | `tf`, `wrapper-tf` |
| PR.DS-02 | `owasp` |
| PR.DS-11 | `tf-plan` |
| PR.IR-01 | `k8s` |
| PR.IR-04 | `k8s` |
| PR.PS-01 | `deploy`, `docker`, `k8s`, `logging` |
| PR.PS-02 | `appsec`, `docker` |
| PR.PS-04 | `logging`, `observability` |
| PR.PS-06 | `appsec`, `deploy`, `github`, `gitops`, `owasp`, `tf`, `tf-plan`, `wrapper-tf` |
| RC.RP-01 | `deploy`, `incident` |
| RS.AN-03 | `incident` |
| RS.CO-02 | `incident` |
| RS.MA-01 | `incident` |
| RS.MI-01 | `incident` |

## MITRE D3FEND

Reference: https://d3fend.mitre.org/

| ID / Technique | Skills |
|---|---|
| Application Configuration Hardening | `appsec`, `ci`, `docker`, `github-actions`, `k8s`, `owasp` |
| Configuration Inventory | `gitops`, `tf`, `tf-plan`, `wrapper-tf` |
| Disk Encryption | `tf`, `wrapper-tf` |
| Input Validation | `owasp` |
| Message Encryption | `owasp` |
| Multi-factor Authentication | `owasp` |
| Network Traffic Filtering | `k8s` |
| Operating System Monitoring | `logging` |
| Platform Hardening | `docker` |
| Platform Monitoring | `logging`, `observability` |
| Restore Software | `deploy` |
| Software Component Inventory | `github` |
| Software Update | `appsec` |
| System Configuration Permissions | `gitops`, `k8s`, `tf`, `tf-plan`, `wrapper-tf` |
| User Account Permissions | `github` |
