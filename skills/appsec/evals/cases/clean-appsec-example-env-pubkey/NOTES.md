# clean-appsec-example-env-pubkey

The same two files as `bad-appsec-committed-secrets`, in the forms that are supposed
to be committed. Nothing may fire, and the pair is what stops these two rules
flagging every repo that documents its own configuration.

- `.env.example` with `USER:PASSWORD@HOST`, `generate-with-openssl-rand-hex-32`, and
  `your-smtp-password-here`. Exclusion 3 covers this twice over: the `.example`
  suffix, and values that are visibly placeholders.
- `deploy.key.pub`, a public key. Exclusion 4: the public half is meant to be
  distributed, and flagging it would train people to ignore the rule that catches the
  private half.

Note the filenames differ from the bad case by a suffix in both instances
(`.env` vs `.env.example`, `deploy.key` vs `deploy.key.pub`). That is the whole
distinction, and a check that greps for "env" or "key" in a filename fails this case
while passing the bad one.
