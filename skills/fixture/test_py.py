#!/usr/bin/env python3
from generated import validate_event, validate_user

pass_ = True


def assert_(condition: bool, message: str) -> None:
    global pass_
    if not condition:
        print(f"FAIL: {message}")
        pass_ = False


assert_(
    len(validate_user({"name": "Alice", "age": 30, "email": "alice@example.com"})) == 0,
    "valid user should have no errors",
)

user_errors = validate_user({"name": "Alice", "age": "thirty", "email": "alice@example.com"})
assert_(len(user_errors) > 0, "invalid user age should produce errors")
assert_(
    any(e["instancePath"] == "/age" for e in user_errors),
    "user age error should reference /age",
)

assert_(
    len(
        validate_event(
            {
                "id": "evt-1",
                "created_at": "2026-01-01T00:00:00Z",
                "status": "active",
                "tags": ["a", "b"],
            }
        )
    )
    == 0,
    "valid event should have no errors",
)

event_errors = validate_event(
    {
        "id": "evt-2",
        "created_at": "2026-01-01T00:00:00Z",
        "status": "deleted",
    }
)
assert_(len(event_errors) > 0, "invalid event status should produce errors")
assert_(
    any(e["instancePath"] == "/status" for e in event_errors),
    "event status error should reference /status",
)

if pass_:
    print("Python validator fixture test PASSED")
    raise SystemExit(0)

print("Python validator fixture test FAILED")
raise SystemExit(1)
