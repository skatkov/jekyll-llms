You are working in a Ruby project that uses mutation testing.

## Goal

Achieve 100% mutation coverage. Verify with:

```sh
bundle exec mutant run
```

When iterating, prefer `--fail-fast` so you address one surviving mutant at a time:

```sh
bundle exec mutant run --fail-fast
```

## When You Find An Alive Mutation

Decide which bucket it falls into:

- **A) The code does too much** for what the tests require. The surviving mutation reveals redundant behavior. The fix is to simplify the implementation.
- **B) A test is missing.** The behavior is intentional but no test observes it. The fix is to add a test.

Decide between A) and B) before changing anything. If unsure, ask the user.

## Constraints

- Line coverage must stay at 100%. Verify with:

```sh
bundle exec rake test
```

- You may not skip mutants by configuring Mutant to ignore them. No matcher ignores, no `coverage_criteria:` tweaks.
- You may not use `send` or `__send__` to invoke private methods in tests just to satisfy Mutant.
- You may not stub or mock the system under test.

## Done

You are done when both commands are green:

```sh
bundle exec rake test
bundle exec mutant run
```
