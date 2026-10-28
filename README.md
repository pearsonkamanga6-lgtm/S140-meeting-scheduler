# S-140 Meeting Scheduler v5.4 - Recent Usage Warning

## NEW in v5.4
✅ App now recognises who was used last week / 2 weeks ago

When you try to assign a publisher who was used:
- Recently (within last 7 days) -> Warning: "Was used recently"
- Last week (7-13 days ago) -> Warning: "Was used last week" 
- 2 weeks ago (14-20 days ago) -> Warning: "Was used 2 weeks ago"

Each warning shows:
- Name, when last used, last part/week
- Options: Continue (OK) or Cancel to choose someone else

Also:
- Dropdowns now show ⚠️ USED LAST WEEK etc.
- Conflict box shows warnings for recent usage
- Works in both root and public/ folders

## How it works
- Uses existing history (finalized weeks)
- Role-specific memory: checks same assignment type (e.g., Bible Reading vs Student)
- General check: if used for ANY assignment in last week, also warns
- Sorted: least recently used appears first in dropdowns

## Deploy to GitHub + Render
1. Push entire folder to GitHub
2. Render -> New Web Service -> Connect repo
3. Build: (empty) Start: npm start
4. Deploy

Health: /api/health
Version: v5.4
