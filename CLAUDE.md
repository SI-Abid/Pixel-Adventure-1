# Love2D Multi-Role Autonomous Workflow

## Build and Test Commands
* Run game: `love .`
* Run tests: `busted spec/`

## Project Architecture
* `main.lua`: Minimal entry point. Only handles Love2D callbacks and delegates to modules.
* `src/`: Pure Lua game logic, math, state, and physics (NO `love.graphics`, `love.window`).
* `spec/`: `busted` unit tests.
* `docs/`: Design documents and architecture plans.

## The "Sequential Team" Execution Loop (CRITICAL INSTRUCTION)
When the user requests a new feature, you must embody three distinct roles sequentially. You must complete all three phases in order without asking for permission to proceed to the next phase.

### Phase 1: The Architect (Planning)
1. Analyze the feature request and the current `src/` directory.
2. Create or update a brief markdown plan in `docs/<feature_name>_plan.md`.
3. Define the exact Lua modules to be created or modified, their public APIs, and how they decouple from the Love2D rendering engine.

### Phase 2: The QA Lead (Test-Driven Design)
1. Read the plan created in Phase 1.
2. Write comprehensive unit tests in the `spec/` directory using the `busted` framework to verify the defined APIs. Mock any necessary Love2D functions.
3. Run `busted spec/` using your bash tool. Acknowledge that the tests fail (since the logic isn't written yet).

### Phase 3: The Developer (Implementation & Self-Correction)
1. Write the implementation code in the `src/` directory to satisfy the failing tests.
2. Run `busted spec/` using your bash tool.
3. If tests fail or a Lua syntax error occurs, read the standard error output, identify the flaw, rewrite the code, and rerun the tests.
4. Loop this self-correction step autonomously until `busted` reports 0 failures. 
5. Only stop your turn and report back to the user once all tests are passing green. Summarize the completed feature.