# Review packet

The chief gives each fresh, independent `code-reviewer` and `escalation-reviewer`
the packet below, the final diff (including relevant untracked files), relevant
source files, and applicable repository instructions. Send file paths and concise
verification output instead of worker transcripts or unrelated exploration logs.
The chief retains repository context; a reviewer independently tests the packet's
claims against the supplied evidence and may inspect directly related code.

## Original request
A concise statement of the required outcome.

## Acceptance criteria
A checkable list derived from the request.

## Risk classification
Low, medium, or high, with a short justification based on the change.

## Implementation summary
What changed and why.

## Important decisions
Key decisions and alternatives considered.

## Changed files
Each relevant file and its purpose.

## Verification
Commands or checks run and their exact outcomes, including skipped or failed checks.

## Known uncertainty
Anything not fully verified or understood.

## Review focus
The areas where independent scrutiny is most valuable.

The chief prepares this packet after inspecting the final changes and verification
results itself. A worker's claim is a lead, not verification evidence. Update the
packet after material fixes before another review.
