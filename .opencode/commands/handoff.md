---
description: Summarize current session state for handoff to next session or another agent, and save it to disk
---

Review the conversation and produce a concise handoff summary covering:

1. **What changed** — files modified, fragments added/edited, DTS changes, kernel version changes
2. **What was tested** — build success/failure, boot test results (with the actual symptom if it failed)
3. **Open issues** — anything left unresolved, with the current hypothesis if one exists. Before writing a hypothesis as "open", check the rest of this conversation for a more recent conclusion that supersedes it — do not report a stale theory as current if it was already confirmed or ruled out later in the session.
4. **Next steps** — the immediate next action, in priority order

Keep it factual and terse — this is for picking up exactly where we left off, not a narrative. If there are uncommitted changes, list them with `git status` output. If there's a known bug being chased, state the current best hypothesis and what would confirm/deny it, and note explicitly if that hypothesis was already tested in this session.

After producing the summary, save it as a file:

1. Create the `handoff/` directory at the repo root if it doesn't exist
2. Determine the current date and time, formatted as `YYYYMMDD_HHMMSS`
3. Write the full summary to `handoff/YYYYMMDD_HHMMSS.md`
4. Confirm the file path to the user after writing it
