# Testing Guidelines (CTRL Framework)

## Close the Loop Protocol

**After writing ANY code in this project:**
1. Write or update the colocated test (`source.test.ts` next to `source.ts`)
2. Run the unit test locally (e.g. `npm run test:unit`)
3. If tests fail → read the error → fix the code → rerun
4. Only report "done" when tests pass
5. Never commit with failing tests

**Full gate before commit:**
Run `npm run ctrl:gate` (build + unit tests). If it fails, fix the underlying issue.

## Test Conventions

- **Colocated:** `utils.test.ts` lives next to `utils.ts`
- **Focus:** Pure logic, validation, security, data transformation
- **Don't test:** UI components, external API calls (mock them), database ops (mock)
- **Always test:** Boundary values (0, 1, max, empty, null), error paths, security checks

## Anti-Redundancy

- Before creating helpers/utilities, search for existing ones
- Import from original source — no re-export wrapper files
- Extract shared test fixtures when reused
