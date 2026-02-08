# jtd-wasm

Ahead-of-time code generator that compiles [RFC 8927 JSON Type Definition](https://www.rfc-editor.org/rfc/rfc8927)
schemas into optimised validation functions -- no interpreter, no AST at
runtime, no dead code.

Two emit targets:

| Target | Output | Use case |
|--------|--------|----------|
| **JavaScript ESM2020** | Standalone `.mjs` module | Browser bundles where JS is fast enough |
| **Rust → WASM** | `.rs` source → `wasm-pack` → `.wasm` | Browser validation where speed and size matter |

The Rust target exists because JavaScript has a performance ceiling.
A JTD schema compiled to Rust, then compiled to WASM via `wasm-pack`,
produces a compact binary that validates JSON in the browser at native
speed.  The path is:

```
JTD schema (JSON)
      │
      ▼
 jtd-codegen (Rust)     ← this crate, runs at build time
      │
      ├──► JavaScript ESM2020 module     (emit_js)
      │
      └──► Rust source file              (emit_rs)
                 │
                 ▼
            cargo / wasm-pack            ← standard Rust toolchain
                 │
                 ▼
            .wasm binary                 ← runs in browser, fast + compact
```

There is no interpreter anywhere in this pipeline.  The generated code
contains exactly the checks the schema requires and nothing else.

## Specification

The code generator implements
[JTD_CODEGEN_SPEC.md](./JTD_CODEGEN_SPEC.md), a language-independent
specification for compiling JTD schemas into target-language source code.

This repository includes a corrected copy of the spec.  The upstream
version had incorrect schema paths in the Section 6.1 table, Section 5.2
code examples, and the Section 8 worked example.  The corrections were
validated against the authoritative
[`json-typedef-spec/tests/validation.json`](https://github.com/jsontypedef/json-typedef-spec)
test suite (316 test cases, all passing for both emitters).

## Crate structure

```
jtd-wasm/
├── jtd-codegen/                  # Core library
│   ├── src/
│   │   ├── ast.rs                # Immutable AST node types (Section 3)
│   │   ├── compiler.rs           # Schema → AST compiler (Section 3.2-3.3)
│   │   ├── emit_js/              # JavaScript ESM2020 emitter (Section 5)
│   │   │   ├── writer.rs         # Indented code builder
│   │   │   ├── types.rs          # TypeKeyword → JS condition strings
│   │   │   ├── context.rs        # Path tracking (instancePath, schemaPath)
│   │   │   ├── nodes.rs          # Per-node emit functions, independently tested
│   │   │   └── emit.rs           # AST walk + composition into full ES module
│   │   └── emit_rs/              # Rust emitter (Section 5, Rust syntax)
│   │       ├── types.rs          # TypeKeyword → Rust condition strings
│   │       ├── context.rs        # Path tracking
│   │       └── emit.rs           # AST walk + composition into full Rust module
│   └── tests/
│       ├── quickjs_validation_suite.rs  # 316 tests: emit JS, run via embedded QuickJS
│       └── rs_validation_suite.rs       # 316 tests: emit Rust, compile, run
└── jtd-wasm-validator/           # Example: emitted Rust compiled to WASM

└── xmake.lua                      # Compatibility suite orchestration (downloads into .tmp/)
```

## Quick start

### Generate a JavaScript validator

```rust
use jtd_codegen::{compiler, emit_js};

let schema = serde_json::from_str(r#"{
  "properties": {
    "name": { "type": "string" },
    "age":  { "type": "uint8" }
  }
}"#).unwrap();

let compiled = compiler::compile(&schema).unwrap();
let js_code = emit_js::emit(&compiled);
// js_code is a standalone ES module with `export function validate(instance)`
```

### Generate a Rust validator

```rust
use jtd_codegen::{compiler, emit_rs};

let schema = serde_json::from_str(r#"{
  "properties": {
    "name": { "type": "string" },
    "age":  { "type": "uint8" }
  }
}"#).unwrap();

let compiled = compiler::compile(&schema).unwrap();
let rs_code = emit_rs::emit(&compiled);
// rs_code is a standalone Rust module with `pub fn validate(instance: &Value) -> Vec<(String, String)>`
```

### Compile to WASM

The Rust emitter output is a `.rs` file that depends only on `serde_json`.
To turn it into a WASM module for the browser:

1. Generate the Rust source with `emit_rs::emit()`
2. Place it in a WASM crate that adds `wasm-bindgen` bindings
3. Build with `wasm-pack build --target web`

The `jtd-wasm-validator/` directory is an example of this pattern.

## Test results

Both emitters pass the complete official JTD validation test suite
(`json-typedef-spec/tests/validation.json`, 316 test cases).

This repo does not vendor the upstream suite. Use xmake to fetch a pinned
revision of `json-typedef-spec` into `.tmp/` and run compatibility tests.

```
xmake run fetch_suite
xmake run test_all
```

`test_wasm` builds the generated Rust validators to `wasm32-wasip1` and runs
them under `wasmtime`. If you run it directly, you may need:

```
rustup target add wasm32-wasip1
```

- **76 unit tests** covering AST, compiler, and individual emitter components
- **316 JS integration tests** (emit JS → run via embedded QuickJS → compare errors)
- **316 Rust integration tests** (emit Rust → compile temp crate → run → compare errors)

## Requirements

- Rust 1.70+
- [xmake](https://xmake.io/) (compatibility suite orchestration)
- `curl` (fetch upstream test suite)
- `wasmtime` (WASM runtime for compatibility tests)
- `wasm-pack` (for WASM compilation)

## Compatibility suite

Fetch the pinned upstream suite into `.tmp/` and run the compatibility tests:

```
xmake run fetch_suite
xmake run test_all
```

WASM tests compile a generated validator to WASI and run it with `wasmtime`.
If you run WASM tests directly, you may need:

```
rustup target add wasm32-wasip1
```
