.PHONY: update clone status

# Pull latest changes for all submodules (tracks their configured branches)
update:
	git submodule update --remote --merge

# Clone workspace with all submodules (for fresh setup)
clone:
	@echo "Run: git clone --recurse-submodules <workspace-repo-url>"

# Show submodule status
status:
	git submodule status
