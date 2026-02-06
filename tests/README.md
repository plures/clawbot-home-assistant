# Test Suite

This directory contains automated tests for the Home Assistant OpenClaw skill.

## Running Tests

```bash
# Run all tests
./run_tests.sh

# Run specific test suite
./test_permission_gate.sh
```

## Test Suites

### test_permission_gate.sh

Tests the security permission gating system to ensure:

1. **Write operations blocked without --intent flag**
   - Service calls without `--intent` are rejected
   - Clear error message shown to user

2. **Dry-run mode works correctly**
   - Shows what would execute without actually executing
   - No actual API calls made in dry-run mode

3. **Read-only scripts work without gating**
   - Probe and list scripts run without permission checks
   - No --intent flag required for read operations

4. **Error handling**
   - Missing tokens fail with clear errors
   - Missing arguments show usage information
   - Help flag works without restrictions

## Test Results

All tests should pass before merging changes:

```
Total tests run: 8
Passed: 8
All tests passed!
```

## Adding New Tests

When adding new functionality:

1. Create a new test script: `test_<feature>.sh`
2. Make it executable: `chmod +x test_<feature>.sh`
3. Follow the pattern in existing tests
4. Run `./run_tests.sh` to verify all tests pass

## CI Integration

These tests can be run in CI pipelines:

```yaml
# Example GitHub Actions step
- name: Run tests
  run: ./tests/run_tests.sh
```
