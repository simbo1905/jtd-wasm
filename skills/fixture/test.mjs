import { validateUser, validateEvent } from "./generated/validators.mjs";

let pass = true;

function assert(condition, message) {
  if (!condition) {
    console.error(`FAIL: ${message}`);
    pass = false;
  }
}

// Valid user
assert(
  validateUser({ name: "Alice", age: 30, email: "alice@example.com" }).length === 0,
  "valid user should have no errors",
);

// Invalid user: wrong type for age
const userErrors = validateUser({ name: "Alice", age: "thirty", email: "alice@example.com" });
assert(userErrors.length > 0, "invalid user age should produce errors");
assert(
  userErrors.some((e) => e.instancePath === "/age"),
  "user age error should reference /age",
);

// Valid event
assert(
  validateEvent({
    id: "evt-1",
    created_at: "2026-01-01T00:00:00Z",
    status: "active",
    tags: ["a", "b"],
  }).length === 0,
  "valid event should have no errors",
);

// Invalid event: bad enum
const eventErrors = validateEvent({
  id: "evt-2",
  created_at: "2026-01-01T00:00:00Z",
  status: "deleted",
});
assert(eventErrors.length > 0, "invalid event status should produce errors");
assert(
  eventErrors.some((e) => e.instancePath === "/status"),
  "event status error should reference /status",
);

if (pass) {
  console.log("MJS validator fixture test PASSED");
  process.exit(0);
} else {
  console.error("MJS validator fixture test FAILED");
  process.exit(1);
}
