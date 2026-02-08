-- xmake orchestration for compatibility tests.
--
-- Run:
--   xmake run fetch_suite
--   xmake run test_rust
--   xmake run test_js
--   xmake run test_all

local JSON_TYPEDEF_SPEC_COMMIT = "71ca275847318717c36f5a2322a8061070fe185d"
local VALIDATION_SHA256 = "ca2ee582044051a690e0a5b79e81f26f4a51623d8a5b73f7a1d488b6e7b11994"

local INVALID_SCHEMAS_SHA256 = "96ac0ab36d73389f2bca1f64896213cf4d30bfc88be8de7b6f1a633cc07be26d"

target("fetch_suite")
    set_kind("phony")
    on_run(function ()
        local dir = path.join(os.projectdir(), ".tmp", "json-typedef-spec", JSON_TYPEDEF_SPEC_COMMIT, "tests")
        local validation = path.join(dir, "validation.json")
        local invalid = path.join(dir, "invalid_schemas.json")

        os.mkdir(dir)

        local base = "https://raw.githubusercontent.com/jsontypedef/json-typedef-spec/" .. JSON_TYPEDEF_SPEC_COMMIT .. "/tests/"
        os.vrunv("curl", {"-f", "-s", "-S", "-L", base .. "validation.json", "-o", validation})
        os.vrunv("curl", {"-f", "-s", "-S", "-L", base .. "invalid_schemas.json", "-o", invalid})

        local function sha256(filepath)
            if os.host() == "windows" then
                -- certutil outputs: "SHA256 hash of file:\n<hex>\nCertUtil: ..."
                local out = os.iorunv("certutil", {"-hashfile", filepath, "SHA256"})
                return out:match("\n(%w+)\n")
            else
                -- shasum works on macOS and Linux
                local out = os.iorunv("shasum", {"-a", "256", filepath})
                return out:match("^(%w+)")
            end
        end

        local vhash = sha256(validation)
        if vhash ~= VALIDATION_SHA256 then
            raise("validation.json sha256 mismatch: expected " .. VALIDATION_SHA256 .. ", got " .. tostring(vhash))
        end

        local ihash = sha256(invalid)
        if ihash ~= INVALID_SCHEMAS_SHA256 then
            raise("invalid_schemas.json sha256 mismatch: expected " .. INVALID_SCHEMAS_SHA256 .. ", got " .. tostring(ihash))
        end

        cprint("${green}Fetched json-typedef-spec tests at ${clear}" .. JSON_TYPEDEF_SPEC_COMMIT)
        cprint("${green}" .. validation .. "${clear}")
    end)
target_end()

target("test_rust")
    set_kind("phony")
    on_run(function ()
        cprint("${cyan}Running:${clear} fetch_suite")
        os.vrunv("xmake", {"run", "fetch_suite"})
        local validation = path.join(os.projectdir(), ".tmp", "json-typedef-spec", JSON_TYPEDEF_SPEC_COMMIT, "tests", "validation.json")
        os.setenv("JTD_VALIDATION_JSON", validation)
        cprint("${cyan}Running:${clear} cargo test -p jtd-codegen --test rs_validation_suite -- --nocapture")
        os.vrunv("cargo", {"test", "-p", "jtd-codegen", "--test", "rs_validation_suite", "--", "--nocapture"})
        cprint("${green}OK:${clear} test_rust")
    end)
target_end()

target("test_js")
    set_kind("phony")
    on_run(function ()
        cprint("${cyan}Running:${clear} fetch_suite")
        os.vrunv("xmake", {"run", "fetch_suite"})
        local validation = path.join(os.projectdir(), ".tmp", "json-typedef-spec", JSON_TYPEDEF_SPEC_COMMIT, "tests", "validation.json")
        os.setenv("JTD_VALIDATION_JSON", validation)
        cprint("${cyan}Running:${clear} cargo test -p jtd-codegen --test quickjs_validation_suite -- --nocapture")
        os.vrunv("cargo", {"test", "-p", "jtd-codegen", "--test", "quickjs_validation_suite", "--", "--nocapture"})
        cprint("${green}OK:${clear} test_js")
    end)
target_end()

target("test_wasm")
    set_kind("phony")
    on_run(function ()
        cprint("${cyan}Running:${clear} fetch_suite")
        os.vrunv("xmake", {"run", "fetch_suite"})
        cprint("${cyan}Running:${clear} rustup target add wasm32-wasip1")
        os.vrunv("rustup", {"target", "add", "wasm32-wasip1"})
        local validation = path.join(os.projectdir(), ".tmp", "json-typedef-spec", JSON_TYPEDEF_SPEC_COMMIT, "tests", "validation.json")
        os.setenv("JTD_VALIDATION_JSON", validation)
        cprint("${cyan}Running:${clear} cargo test -p jtd-codegen --test wasmtime_validation_suite -- --nocapture")
        os.vrunv("cargo", {"test", "-p", "jtd-codegen", "--test", "wasmtime_validation_suite", "--", "--nocapture"})
    end)
target_end()

target("test_all")
    set_kind("phony")
    on_run(function ()
        cprint("${cyan}Running:${clear} fetch_suite")
        os.vrunv("xmake", {"run", "fetch_suite"})
        local validation = path.join(os.projectdir(), ".tmp", "json-typedef-spec", JSON_TYPEDEF_SPEC_COMMIT, "tests", "validation.json")
        os.setenv("JTD_VALIDATION_JSON", validation)
        cprint("${cyan}Running:${clear} cargo test -p jtd-codegen --test rs_validation_suite -- --nocapture")
        os.vrunv("cargo", {"test", "-p", "jtd-codegen", "--test", "rs_validation_suite", "--", "--nocapture"})
        cprint("${cyan}Running:${clear} cargo test -p jtd-codegen --test quickjs_validation_suite -- --nocapture")
        os.vrunv("cargo", {"test", "-p", "jtd-codegen", "--test", "quickjs_validation_suite", "--", "--nocapture"})
        cprint("${cyan}Running:${clear} xmake run test_wasm")
        os.vrunv("xmake", {"run", "test_wasm"})
        cprint("${green}OK:${clear} test_all")
    end)
target_end()
