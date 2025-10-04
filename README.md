# quizzard-thesis

- lib/screens => UI only, no DB calls here.
- lib/repositories => all DB logic (CRUD). Use these inside screens.
- lib/models => pure data classes.
- lib/services => helper classes (CSV, sprite manager, etc).
- lib/db => central database setup (DO NOT edit except for schema changes).