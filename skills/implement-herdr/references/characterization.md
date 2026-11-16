# Characterization seams

Read after `tdd.md` and your kind's file, for a seam in `characterize` mode.

A seam in `characterize` mode pins the current behaviour of existing code so a refactor can prove it preserved it. It is still a `unit` or `integration` seam, and every rule for its kind applies, except red before green:

- **Green on first write.** The code already exists, so the test passes the moment it's written. If it fails, you've found a disagreement between the plan and the code: report `needs-decision`, don't change the code to match.
- **Expected values come from observed behaviour.** Run the code, record what it does, and assert that, including behaviour that looks wrong. Fixing it is a separate, behaviour-changing seam, never part of a characterization.
- **Frozen for the rest of the refactor.** No later seam edits or deletes a characterization test. If a later seam can't keep it green, that seam reports `needs-decision`.
- **Pin the edges the refactor could move.** Cover the behaviour the planned restructuring touches, edges included; don't pin behaviour outside the plan's reach.

A later seam may rewrite or delete an existing test only when the plan assigns that test to it, and may delete one only when the plan names the characterization seam that covers its behaviour.
