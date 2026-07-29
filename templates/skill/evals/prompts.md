# Trigger-phrase evals: <skill-name>

The description in `SKILL.md` is the only text the model reads when deciding
whether to load this skill. These are the prompts that decision has to get right.

Verify with `EVALS=1 bash scripts/run-behavioral-evals.sh --triggers <skill-name>`.

## Should load

Phrases someone would actually type. Not slash commands, not a summary of the
skill. At least four.

- "<a request in the words a colleague would use>"
- "<a request naming the artifact rather than the skill>"
- "<a symptom rather than a request>"
- "<a question this skill answers>"

## Should not load

Where the boundary is. Each line says where it should go instead, so a failure
tells you which skill over-triggered rather than only that one did.

- "<a prompt that belongs to a neighbouring skill>" → `<other-skill>`
- "<a prompt too vague to route anywhere>" → ask, load nothing
