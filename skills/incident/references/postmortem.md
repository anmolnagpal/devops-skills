# Writing a postmortem that changes something

Load this when writing or reviewing a postmortem. The template lives in the skill body;
this is about the language, which is where postmortems actually fail.

## The rewrite table

Blame is rarely explicit. It arrives as a sentence about a person where a sentence about
a system belongs.

| Written | Rewritten | Why |
|---|---|---|
| "Priya deployed without running the tests." | "The deploy path allowed a change to reach prod without a passing test run." | The second sentence has a fix. The first has a target. |
| "The engineer misread the runbook." | "The runbook's step 3 could be read two ways; the ambiguous phrasing is quoted below." | Now someone can edit step 3. |
| "Human error." | "The interface allowed a destructive action with no confirmation and no undo." | "Human error" is where an investigation stops one question early. |
| "We should have noticed sooner." | "Time to detect was 47 minutes. No alert covered queue depth, which was the first observable symptom." | A number and a named gap instead of a feeling. |
| "The on-call was slow to respond." | "The page arrived at 03:12 and was acked at 03:26. The escalation policy allows 15 minutes." | If 14 minutes is too slow, change the policy, not the person. |
| "Someone forgot to update the config." | "Config in two places had to be kept in sync manually, with nothing checking they matched." | Names the duplication, which is the actual defect. |
| "Lack of communication." | "There was no single incident channel for the first 20 minutes; three parallel threads existed." | Fixable with a process. |
| "We got lucky." | "The blast radius was limited because the change was behind a flag at 5% traffic." | That was a control working, not luck. Say so, so it survives the next refactor. |

## Counterfactuals

"If only we had X" describes a world that did not happen. It feels like analysis and
teaches nothing, because the reason X did not happen is the thing worth understanding.

- "If we had caught it in staging" → why did staging not catch it? What differs?
- "If the alert had fired" → why did it not? Did it exist? Was it silenced? Wrong
  threshold?
- "If we had rolled back sooner" → what made rollback feel risky at the time?

The last one is the most productive question in most postmortems. People delay rollback
because they are unsure it is safe, and that uncertainty is a fixable engineering
problem.

## Contributing factors stay plural

There is a strong pull toward one cause, because one cause makes a tidy narrative and a
short document. It is almost always the shortest version of the truth rather than the
truth.

A useful test: for each factor you list, ask whether removing it alone would have
prevented the incident. If exactly one factor passes, keep looking. Real incidents need
several things to line up, and the ones you did not list are the ones that will line up
again.

## Action items

Every one gets an owner, a date, and a ticket. Anything without all three is a wish.

**Not action items:** "be more careful", "add more monitoring", "improve
documentation", "consider refactoring X", "investigate Y".

**Action items:** "add a queue-depth alert at 5000 with a runbook link, owner Dana, due
2026-08-12, PLAT-4471". "Remove the duplicated region config by reading it from the
labels module, owner Sam, due 2026-08-20, PLAT-4472."

Sort them by whether they reduce likelihood or reduce impact, and be honest that
impact-reducers are usually more valuable. You cannot prevent every cause; you can make
the next one shorter.

Cap the list. Twenty action items means none of them happen. Five that are done beats
twenty that are filed.

## "What we are not doing"

The section most postmortems omit and most teams need. Options considered and rejected,
with the reason:

> **Rejected: multi-region active-active for the ledger service.** It would have
> prevented this class of outage. It also roughly doubles infrastructure cost and adds a
> consistency problem we do not currently have to solve. Revisit if we see a second
> region-level incident, or if the availability target moves above 99.95%.

Without this, the same suggestion returns every quarter and the same conversation
happens from scratch. With it, the decision has a stated trigger for revisiting, which
is what makes it a decision rather than a deferral.

## Timelines

Two rules that matter more than they look:

**One timezone, stated.** UTC unless the whole team is in one place. A timeline mixing
local times across participants cannot be reconstructed.

**Separate what happened from what was observed.** The trigger often precedes detection
by a long way, and the gap between them is the most actionable number in the document.

| Time (UTC) | Event |
|---|---|
| 02:41 | Deploy of `ledger-api` v2.7.1 completes. Connection pool size reduced from 40 to 8 by an unrelated config refactor. |
| 02:44 | Settlement latency begins rising. No alert covers this. |
| 03:12 | Queue depth alert fires. **Time to detect: 31 minutes.** |
| 03:26 | On-call acks. |
| 03:31 | Rollback started. |
| 03:38 | Latency normal. **Time to mitigate: 26 minutes from detection, 57 from onset.** |

Deriving both numbers explicitly is what turns a narrative into something measurable
across incidents.

## Reviewing someone else's postmortem

1. Does any sentence have a person as the subject of a failure? Rewrite it.
2. Is there exactly one contributing factor? Keep looking.
3. Does any action item lack an owner, a date, or a ticket?
4. Are there more than about seven action items? Cut.
5. Is "what went well" empty or padded? Both are signals. Something limited the damage;
   name it so it does not get removed later by someone who does not know it was load
   bearing.
6. Is time to detect stated as a number?
7. Would someone who was not there understand what broke, from this document alone?

## The one-line test

If the document's conclusion is that people should try harder, it is not finished. If it
is that a specific system permitted a specific bad outcome and here is the change, it
is.
