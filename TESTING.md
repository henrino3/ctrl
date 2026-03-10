# Testing Guide

## Philosophy

We use **close the loop** — AI agents write code AND tests, verify before reporting done.

## Pattern
- **Colocated:** Tests live next to the source files (`filename.test.ts`).

## What to Test

### ✅ DO Test
**Pure logic functions:**
- Data transformation/parsing
- Utility functions
- Validation functions  
- Configuration parsing

**API routes (unit):**
- Input validation
- Error handling
- Response formatting

### ❌ DON'T Test
- UI/visual components (use E2E tools for those)
- External API calls (mock them)
- Database operations (mock or use a test DB)

## Close the Loop Protocol

1. **Write code → write test**
2. **Run tests locally** before marking a task complete
3. **If test fails → fix code → rerun tests**
4. **Never push code with failing tests**

## Anti-Patterns

- ❌ Tests that always pass (no real assertion)
- ❌ Testing implementation details instead of behavior
- ❌ Skipping tests to "save time"
