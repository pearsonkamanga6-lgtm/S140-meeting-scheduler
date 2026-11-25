# S-140 Meeting Scheduler v6.0 — Local AI profile assistant and family pairing

- Preserves assignments when refreshing matching meeting parts; changed parts require review.
- Checks prior draft and finalized assignments and warns about future scheduled repetitions.
- Records auxiliary counselors; detects simultaneous roles and blocks hard errors at finalization.
- Keeps selected publishers visible when eligibility or availability changes.
- Validates backup files and saves a recovery checkpoint before replacing data.
- Fits long weekly PDFs to the page without silently dropping trailing words in ordinary wrapped cells.
- Updates the offline cache and restricts the static server to app assets.

Existing local browser storage key is unchanged. Export a backup before upgrading.
Data is device-local; no cloud sync yet.
Run `npm start`; health endpoint: `/api/health`.

## Intelligent rotation
- Review recommendations for unfilled assignments, or view eligible roles for a publisher.
- Both publisher and householder roles count toward the prior two weeks. Upcoming nearby assignments also count.
- Recent publishers are excluded by default; an explicit override allows review when necessary.
- Uses approved eligibility only, same-gender pairings, and no second assignment in the same generated week.
- Existing assignments are retained. Review workbook classifications before applying; ambiguous parts remain manual.
- Does not model family-member exceptions, age, experience, or local approval; the overseer reviews the result.

## Generate Automatic Schedule
- Dedicated one-command schedule generator for the current week; review eligibility and workbook first.
- Searches for the largest feasible set of compatible assignments, with a bounded search and explicit incomplete reporting.
- Preserves existing assignments and saves a recoverable draft; recent-use exceptions require opt-in.
- Student talks now have a separate brother-only eligibility checkbox. Existing names are retained but must be reviewed if a talk approval was not recorded.

## Fetch & Schedule All Online Weeks
- Discovers published upcoming Cinyanja workbook issues and week links from official JW.org.
- Imports validated programmes, schedules in chronological order using previous planned weeks as history.
- Saves only after user review; preserves assigned, archived and finalized weeks and reports parse failures, unavailable roles and search limits.
- Uses the current week by default, with adjustable start date and new-week auxiliary classroom preference.
- Unrecognized ministry headings remain manual. No publisher data is sent to JW.org.

## Suggested schedule PDFs
- Preview or download a proposed individual week directly from online review.
- Preview or download all proposed weeks in one chronological landscape PDF, one page per week.
- PDFs are generated from the proposed snapshot (not the currently open saved week) and marked as draft, including an incomplete warning when applicable.
- Export does not save or finalize the schedule; existing review and save controls remain separate.

## Publisher profile chat
- Describe observable strengths, review and confirm extracted ability profiles; optional browser on-device LanguageModel, local rules otherwise. Local speech recognition only, when supported.
- Match confirmed strengths and experience to estimated assignment difficulty, with manual overrides and reasons; no age, title, pioneer status or inferred personality scoring. Qualifications remain mandatory.
- Confirm reciprocal family links explicitly; mixed-gender demonstrations are permitted only for verified family members.
- Notes remain in device storage and exported backups, not PDFs or remote AI requests. Avoid confidential personal details. Existing public seed names remain a separate privacy issue.
