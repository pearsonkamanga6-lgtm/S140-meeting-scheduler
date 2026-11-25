# S-140 Meeting Scheduler v5.6 — Intelligent rotation

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
