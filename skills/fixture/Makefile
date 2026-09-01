JTD_CODEGEN ?= ../../target/release/jtd-codegen
SCHEMA_DIR  := schemas
OUT_DIR     := generated
SCHEMAS     := $(wildcard $(SCHEMA_DIR)/*.jdt.json)
VALIDATORS  := $(patsubst $(SCHEMA_DIR)/%.jdt.json,$(OUT_DIR)/%.mjs,$(SCHEMAS))

.PHONY: validators clean-validators test-validators

validators: $(VALIDATORS) $(OUT_DIR)/validators.mjs

$(OUT_DIR)/%.mjs: $(SCHEMA_DIR)/%.jdt.json
	@mkdir -p $(OUT_DIR)
	$(JTD_CODEGEN) --target js $< > $@

$(OUT_DIR)/validators.mjs: $(VALIDATORS)
	@mkdir -p $(OUT_DIR)
	@rm -f $@
	@for f in $(VALIDATORS); do \
	  stem=$$(basename "$$f" .mjs); \
	  cap=$$(node -e 'const stem = process.argv[1]; process.stdout.write(stem.replace(/(^|-)([a-z])/g, (_, __, c) => c.toUpperCase()))' "$$stem"); \
	  echo "export { validate as validate$$cap } from \"./$$stem.mjs\";" >> $@; \
	done

clean-validators:
	rm -rf $(OUT_DIR)

test-validators: validators
	node test.mjs
