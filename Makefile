# stylua from PATH, else Mason's (only if it is executable).
STYLUA ?= $(shell command -v stylua 2>/dev/null || { test -x $(HOME)/.local/share/nvim/mason/bin/stylua && echo $(HOME)/.local/share/nvim/mason/bin/stylua; })

.PHONY: test unit smoke fmt fmt-check startup

test: fmt-check unit smoke

# lua/minh/wrap.lua, no plugins
unit:
	nvim --clean --headless -l tests/wrap_spec.lua

# the whole config, headless, every plugin loaded
smoke:
	nvim --headless -c "luafile tests/smoke.lua"

fmt:
	@test -n "$(STYLUA)" || { echo "stylua not found or not executable (chmod +x the Mason binary)"; exit 1; }
	$(STYLUA) .

fmt-check:
	@if [ -z "$(STYLUA)" ]; then echo "fmt-check skipped: stylua not found or not executable"; else $(STYLUA) --check .; fi

startup:
	rm -f /tmp/nvim-startup.log && nvim --headless --startuptime /tmp/nvim-startup.log +qa && grep "NVIM STARTED" /tmp/nvim-startup.log
