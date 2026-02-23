.PHONY: update clone status help setup check-python-version diagnose-python
.PHONY: poetry-install poetry-update poetry-shell poetry-env-create poetry-env-update
.PHONY: poetry-export poetry-lock poetry-clean poetry-check
.PHONY: test lint format pre-commit-install pre-commit-run

# Default target
.DEFAULT_GOAL := help

# ============================================================================
# Git Submodule Management
# ============================================================================

## Pull latest changes for all submodules (tracks their configured branches)
update:
	@git submodule foreach --quiet ' \
		branch=$$(git config -f "$$toplevel/.gitmodules" submodule.$$name.branch || echo master); \
		echo "==> $$name: fetching origin/$$branch"; \
		git fetch origin "$$branch" --quiet && \
		git checkout "$$branch" --quiet 2>/dev/null || git checkout -b "$$branch" "origin/$$branch" --quiet && \
		git reset --hard "origin/$$branch" --quiet && \
		echo "    $$name: updated to $$(git rev-parse --short HEAD)" \
	'

## Clone workspace with all submodules (for fresh setup)
clone:
	@echo "Run: git clone --recurse-submodules <workspace-repo-url>"

## Show submodule status
status:
	git submodule status

# ============================================================================
# Python Environment Management (Poetry)
# ============================================================================

## Check Python version matches project requirements
check-python-version:
	@REQUIRED_VERSION="3.11.14"; \
	CURRENT_VERSION=$$(python --version 2>&1 | cut -d' ' -f2); \
	if [ "$$CURRENT_VERSION" != "$$REQUIRED_VERSION" ]; then \
		echo "❌ Python version mismatch!"; \
		echo ""; \
		echo "Required: $$REQUIRED_VERSION"; \
		echo "Current:  $$CURRENT_VERSION"; \
		echo ""; \
		echo "📝 To fix this:"; \
		echo ""; \
		echo "If Python 3.11.14 is already installed (pyenv says 'already exists'):"; \
		echo "   cd $$(pwd)"; \
		echo "   pyenv local 3.11.14"; \
		echo "   exec \$$SHELL"; \
		echo "   python --version"; \
		echo ""; \
		echo "If you need to install it:"; \
		echo "   brew install pyenv"; \
		echo "   pyenv install 3.11.14"; \
		echo "   pyenv local 3.11.14"; \
		echo "   exec \$$SHELL"; \
		echo ""; \
		echo "Then re-run:"; \
		echo "   make setup"; \
		echo ""; \
		exit 1; \
	else \
		echo "✅ Python version $$CURRENT_VERSION is correct"; \
	fi

## Diagnose Python environment issues
diagnose-python:
	@echo "=========================================="
	@echo "Python Environment Diagnostics"
	@echo "=========================================="
	@echo ""
	@echo "Python version:"
	@python --version || echo "  ❌ python command not found"
	@echo ""
	@echo "Python path:"
	@which python || echo "  ❌ python not in PATH"
	@echo ""
	@echo "Pyenv installed:"
	@pyenv --version 2>/dev/null || echo "  ❌ pyenv not found"
	@echo ""
	@echo "Pyenv versions:"
	@pyenv versions 2>/dev/null || echo "  ❌ pyenv not configured"
	@echo ""
	@echo "Local .python-version file:"
	@cat .python-version 2>/dev/null || echo "  ❌ .python-version file not found"
	@echo ""
	@echo "Current directory:"
	@pwd
	@echo ""
	@echo "Shell:"
	@echo $$SHELL
	@echo ""
	@echo "=========================================="
	@echo ""
	@echo "💡 If python version is wrong:"
	@echo "   1. Run: pyenv local 3.11.14"
	@echo "   2. Run: exec \$$SHELL"
	@echo "   3. Run: make check-python-version"
	@echo ""

## Complete environment setup (installs Poetry, creates venv, installs dependencies, sets up pre-commit)
setup: check-python-version poetry-install-tool
	@echo "=========================================="
	@echo "🚀 Starting complete environment setup..."
	@echo "=========================================="
	@echo ""
	@echo "Step 1/4: Creating virtual environment and installing dependencies..."
	@poetry install --no-root --with dev,test
	@echo "✅ Virtual environment created"
	@echo ""
	@echo "Step 2/4: Installing pre-commit hooks..."
	@poetry run pre-commit install
	@echo "✅ Pre-commit hooks installed"
	@echo ""
	@echo "Step 3/4: Running initial pre-commit checks..."
	@poetry run pre-commit run --all-files || echo "⚠️  Some pre-commit checks failed (this is normal for first run)"
	@echo ""
	@echo "Step 4/4: Verifying environment..."
	@poetry run python --version
	@echo ""
	@echo "=========================================="
	@echo "✅ Environment setup complete!"
	@echo "=========================================="
	@echo ""
	@echo "Next steps:"
	@echo "  1. Activate environment:  poetry shell"
	@echo "  2. Verify setup:          make poetry-env-info"
	@echo "  3. Run tests:             make test"
	@echo "  4. View all commands:     make help"
	@echo ""

## Install Poetry (if not already installed)
poetry-install-tool:
	@if ! command -v poetry &> /dev/null; then \
		echo "Installing Poetry..."; \
		curl -sSL https://install.python-poetry.org | python3 -; \
		echo "Poetry installed. Add to PATH: export PATH=\"\$$HOME/.local/bin:\$$PATH\""; \
	else \
		echo "Poetry is already installed: $$(poetry --version)"; \
	fi

## Create virtual environment and install dependencies
poetry-env-create: poetry-install-tool
	@echo "Creating virtual environment with Poetry..."
	poetry install --no-root
	@echo "✅ Virtual environment created successfully"
	@echo "To activate: poetry shell"

## Update all dependencies to their latest compatible versions
poetry-env-update:
	@echo "Updating dependencies..."
	poetry update
	@echo "✅ Dependencies updated"

## Install/sync dependencies (after pulling changes)
poetry-install:
	@echo "Installing dependencies from lock file..."
	poetry install --no-root
	@echo "✅ Dependencies installed"

## Install with dev dependencies
poetry-install-dev:
	@echo "Installing with dev dependencies..."
	poetry install --no-root --with dev,test
	@echo "✅ Dev dependencies installed"

## Lock dependencies without installing
poetry-lock:
	@echo "Locking dependencies..."
	poetry lock --no-update
	@echo "✅ poetry.lock updated"

## Export requirements.txt (for environments without Poetry)
poetry-export:
	@echo "Exporting requirements.txt..."
	poetry export -f requirements.txt --output requirements.txt --without-hashes
	@echo "Exporting requirements-dev.txt..."
	poetry export -f requirements.txt --output requirements-dev.txt --without-hashes --with dev,test
	@echo "✅ requirements.txt and requirements-dev.txt created"

## Check pyproject.toml validity
poetry-check:
	@echo "Checking pyproject.toml..."
	poetry check
	@echo "✅ pyproject.toml is valid"

## Activate Poetry shell
poetry-shell:
	@echo "Run: poetry shell"

## Show current virtual environment info
poetry-env-info:
	@echo "Poetry environment info:"
	@poetry env info
	@echo ""
	@echo "Installed packages:"
	@poetry show --tree

## Clean Poetry cache and virtual environments
poetry-clean:
	@echo "Cleaning Poetry cache..."
	poetry cache clear --all pypi -n
	@echo "Removing virtual environment..."
	poetry env remove --all
	@echo "✅ Poetry cache and environments cleaned"

# ============================================================================
# Code Quality
# ============================================================================

## Run tests with pytest
test:
	@echo "Running tests..."
	poetry run pytest

## Run linters (black, isort, flake8)
lint:
	@echo "Running black (check only)..."
	poetry run black --check .
	@echo "Running isort (check only)..."
	poetry run isort --check-only .
	@echo "Running flake8..."
	poetry run flake8 .
	@echo "✅ Linting complete"

## Format code with black and isort
format:
	@echo "Formatting code with black..."
	poetry run black .
	@echo "Sorting imports with isort..."
	poetry run isort .
	@echo "✅ Code formatted"

## Run type checking with mypy
typecheck:
	@echo "Running mypy..."
	poetry run mypy .
	@echo "✅ Type checking complete"

## Install pre-commit hooks
pre-commit-install:
	@echo "Installing pre-commit hooks..."
	poetry run pre-commit install
	@echo "✅ Pre-commit hooks installed"

## Run pre-commit on all files
pre-commit-run:
	@echo "Running pre-commit on all files..."
	poetry run pre-commit run --all-files
	@echo "✅ Pre-commit checks complete"

## Run all quality checks
check-all: lint typecheck test
	@echo "✅ All checks passed"

# ============================================================================
# Development Helpers
# ============================================================================

## Start Jupyter Lab
jupyter:
	@echo "Starting Jupyter Lab..."
	poetry run jupyter lab

## Start IPython shell
ipython:
	@echo "Starting IPython..."
	poetry run ipython

# ============================================================================
# Help
# ============================================================================

## Show this help message
help:
	@echo "MRGE Data Team Workspace - Makefile Commands"
	@echo ""
	@echo "🚀 Quick Setup:"
	@echo "  make setup               - Complete environment setup (recommended for first time)"
	@echo ""
	@echo "Git Submodule Management:"
	@echo "  make update              - Pull latest changes for all submodules"
	@echo "  make status              - Show submodule status"
	@echo ""
	@echo "Python Environment (Poetry):"
	@echo "  make setup               - Complete setup (Poetry + venv + deps + pre-commit)"
	@echo "  make check-python-version - Check if Python version matches requirements (3.11.14)"
	@echo "  make diagnose-python     - Diagnose Python environment issues"
	@echo "  make poetry-install-tool - Install Poetry (if not installed)"
	@echo "  make poetry-env-create   - Create venv and install all dependencies"
	@echo "  make poetry-install      - Install/sync dependencies from lock file"
	@echo "  make poetry-install-dev  - Install with dev dependencies"
	@echo "  make poetry-env-update   - Update all dependencies to latest versions"
	@echo "  make poetry-lock         - Update poetry.lock without installing"
	@echo "  make poetry-export       - Export requirements.txt files"
	@echo "  make poetry-check        - Validate pyproject.toml"
	@echo "  make poetry-env-info     - Show environment and package info"
	@echo "  make poetry-clean        - Clean cache and remove virtual environments"
	@echo ""
	@echo "Code Quality:"
	@echo "  make test                - Run pytest tests"
	@echo "  make lint                - Run linters (black, isort, flake8)"
	@echo "  make format              - Format code with black and isort"
	@echo "  make typecheck           - Run mypy type checking"
	@echo "  make pre-commit-install  - Install pre-commit hooks"
	@echo "  make pre-commit-run      - Run pre-commit on all files"
	@echo "  make check-all           - Run all quality checks"
	@echo ""
	@echo "Development:"
	@echo "  make jupyter             - Start Jupyter Lab"
	@echo "  make ipython             - Start IPython shell"
	@echo ""
	@echo "Quick Start (First Time):"
	@echo "  1. make setup                # Complete automated setup"
	@echo "  2. poetry shell              # Activate environment"
	@echo "  3. make test                 # Verify everything works"
	@echo ""
	@echo "Quick Start (After git pull):"
	@echo "  1. make poetry-install       # Sync dependencies"
	@echo "  2. poetry shell              # Activate environment"
	@echo ""
