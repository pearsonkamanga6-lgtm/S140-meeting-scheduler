# S-140 Meeting Scheduler v5.5 — Reliability and recovery

- Preserves assignments when refreshing matching meeting parts; changed parts require review.
- Checks prior draft and finalized assignments and warns about future scheduled repetitions.
- Records auxiliary counselors; detects simultaneous roles and blocks hard errors at finalization.
- Keeps selected publishers visible when eligibility or availability changes.
- Validates backup files and saves a recovery checkpoint before replacing data.
- Fits long weekly PDFs to the page without silently dropping trailing words in ordinary wrapped cells.
- Updates the offline cache and restricts the static server to app assets.

Existing local browser storage key is unchanged. Export a backup before upgrading.
Data is device-local; no cloud sync or automatic assignment yet.
Run `npm start`; health endpoint: `/api/health`.
