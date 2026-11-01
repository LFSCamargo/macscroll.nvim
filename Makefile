ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
HANDLER := $(ROOT)/handler/darwin
# $NVIM is a parent-editor listen socket. Do not use it as the binary.
# nvim.setup's ~/.local/bin/nvim wrapper rewrites --clean; skip it.
export NVIM_WRAPPER ?= 0
NVIM_BIN ?= nvim
SWIFT ?= swift

.PHONY: all worker test test-lua test-swift test-nvim e2e check install uninstall

all: test

worker:
	@bash "$(ROOT)/scripts/macscroll.sh" build

install:
	@bash "$(ROOT)/scripts/macscroll.sh" install

uninstall:
	@bash "$(ROOT)/scripts/macscroll.sh" uninstall

test-lua:
	@$(NVIM_BIN) --clean --headless -u NONE -l "$(ROOT)/tests/lua/run.lua"

test-swift:
	@if command -v $(SWIFT) >/dev/null 2>&1 && [ "$$(uname -s)" = Darwin ]; then \
		$(SWIFT) run --package-path "$(HANDLER)" MacscrollCoreTests; \
	else \
		echo 'skip swift tests (Darwin + swift required)'; \
	fi

e2e:
	@E2E_DIR="$${E2E_DIR:-$$(mktemp -d)}" MACSCROLL_ROOT="$(ROOT)" \
		$(NVIM_BIN) --clean --headless -u "$(ROOT)/tests/e2e/init.lua" -l "$(ROOT)/tests/e2e/e2e.lua"

test-nvim:
	@E2E_DIR="$${E2E_DIR:-$$(mktemp -d)}" MACSCROLL_ROOT="$(ROOT)" \
		$(NVIM_BIN) --clean --headless -u NONE -l "$(ROOT)/tests/nvim/suite.lua"

check: test-lua test-swift
	@bash -n "$(ROOT)/scripts/macscroll.sh"

test: check e2e test-nvim
