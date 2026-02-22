# MRGE Data Team Workspace - Python Environment Guide

## Overview

This workspace provides a unified Python environment using Poetry that consolidates dependencies from:
- `data-platform-etl` (Airflow, dbt, Databricks)
- Development tools (testing, linting, formatting)
- Jupyter notebooks and interactive development

## Prerequisites

### Python Version: 3.11.14 (Required)

This workspace requires **Python 3.11.14** specifically. This version matches the production environment in `data-platform-etl`.

**Check your current version:**
```bash
python --version
```

**If you need to install Python 3.11.14:**

Using pyenv (recommended):
```bash
# Install pyenv (macOS)
brew install pyenv

# Add to shell profile (~/.zshrc or ~/.bashrc)
echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init --path)"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
source ~/.zshrc

# Install Python 3.11.14
pyenv install 3.11.14

# If you see "already exists" - skip this step, it's already installed

# Set as local version for this workspace
cd /path/to/mrge-data-team-ai-vscode
pyenv local 3.11.14

# IMPORTANT: Restart your terminal or reload shell
exec $SHELL

# Verify
python --version  # Should output: Python 3.11.14
```

**Troubleshooting:**
- If `python --version` still shows the wrong version after `pyenv local`:
  1. Make sure pyenv is initialized in your shell profile
  2. Restart your terminal completely
  3. Run `python --version` again
- If the issue persists, check that `.python-version` file exists in the workspace root:
  ```bash
  cat .python-version  # Should show: 3.11.14
  ```

**Ensure pyenv is properly configured in your shell:**

For **zsh** (~/.zshrc):
```bash
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
```

For **bash** (~/.bash_profile or ~/.bashrc):
```bash
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
```

After editing, reload your shell:
```bash
source ~/.zshrc   # or source ~/.bashrc
```

**Verify before proceeding:**
```bash
# Check Python version
make check-python-version
```

## Quick Start

### Automated Setup (Recommended)

**One command to set up everything:**

```bash
make setup
```

This single command will:
- ✅ Verify Python version is 3.11.14
- ✅ Install Poetry (if not already installed)
- ✅ Create virtual environment in `.venv/`
- ✅ Install all dependencies (production + dev + test)
- ✅ Set up pre-commit hooks (auto-format on commit)
- ✅ Run initial code quality checks
- ✅ Verify the Python environment

**If you have the wrong Python version**, the setup will fail with clear instructions on how to install 3.11.14.

### Manual Setup (Step-by-Step)

If you prefer to understand each step:

**1. Install Poetry**

```bash
make poetry-install-tool
```

Or manually:
```bash
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$HOME/.local/bin:$PATH"  # Add to ~/.zshrc or ~/.bashrc
```

**2. Create Environment**

```bash
make poetry-env-create
```

This will:
- Create a `.venv/` directory in the workspace root
- Install all dependencies from `pyproject.toml`
- Set up development tools (pytest, black, isort, etc.)

**3. Install Pre-commit Hooks (Optional but Recommended)**

```bash
make pre-commit-install
```

**4. Activate Environment**

```bash
poetry shell
```

Or run commands directly:
```bash
poetry run python script.py
poetry run pytest
poetry run jupyter lab
```

## Makefile Commands

### Complete Setup

| Command | Description |
|---------|-------------|
| `make setup` | **Complete automated setup** (Poetry + venv + deps + pre-commit) |
| `make help` | Show all available commands |

### Environment Management

| Command | Description |
|---------|-------------|
| `make poetry-install-tool` | Install Poetry (if not already installed) |
| `make poetry-env-create` | Create virtual environment and install dependencies |
| `make poetry-install` | Install/sync dependencies from lock file |
| `make poetry-install-dev` | Install with dev dependencies |
| `make poetry-env-update` | Update all dependencies to latest versions |
| `make poetry-lock` | Update `poetry.lock` without installing |
| `make poetry-export` | Export `requirements.txt` files |
| `make poetry-check` | Validate `pyproject.toml` |
| `make poetry-env-info` | Show environment and package info |
| `make poetry-clean` | Clean cache and remove environments |

### Code Quality

| Command | Description |
|---------|-------------|
| `make format` | Format code with black and isort |
| `make lint` | Run linters (check only) |
| `make typecheck` | Run mypy type checking |
| `make test` | Run pytest tests |
| `make pre-commit-install` | Install pre-commit git hooks |
| `make pre-commit-run` | Run pre-commit on all files |
| `make check-all` | Run all quality checks |

### Development

| Command | Description |
|---------|-------------|
| `make jupyter` | Start Jupyter Lab |
| `make ipython` | Start IPython shell |
| `make help` | Show all available commands |

## Dependency Management

### Adding Dependencies

```bash
# Add a production dependency
poetry add <package>

# Add a dev dependency
poetry add --group dev <package>

# Add with specific version
poetry add "package==1.2.3"
poetry add "package>=1.2.0,<2.0"
```

### Removing Dependencies

```bash
poetry remove <package>
poetry remove --group dev <package>
```

### Updating Dependencies

```bash
# Update all dependencies
make poetry-env-update

# Update specific package
poetry update <package>

# Show outdated packages
poetry show --outdated
```

### Exporting Requirements

For environments that don't use Poetry (Docker, MWAA, etc.):

```bash
make poetry-export
```

This creates:
- `requirements.txt` - Production dependencies only
- `requirements-dev.txt` - All dependencies including dev/test

## Configuration

### pyproject.toml

Main configuration file containing:
- **[tool.poetry.dependencies]** - Production dependencies
- **[tool.poetry.group.dev.dependencies]** - Development tools
- **[tool.poetry.group.test.dependencies]** - Testing tools
- **[tool.black]** - Code formatting rules
- **[tool.isort]** - Import sorting rules
- **[tool.pytest.ini_options]** - Test configuration
- **[tool.mypy]** - Type checking settings

### poetry.toml

Local Poetry configuration:
- Virtual environments created in `.venv/` (in-project)
- Uses active Python version (3.11.14)

### .python-version

Specifies required Python version: **3.11.14**

Used by:
- `pyenv` - Automatic version switching
- Poetry - Environment creation
- IDE/editors - Python interpreter selection

## Troubleshooting

### Poetry Not Found

```bash
# Install Poetry
make poetry-install-tool

# Verify installation
poetry --version

# If not in PATH, add to ~/.zshrc or ~/.bashrc:
export PATH="$HOME/.local/bin:$PATH"
```

### Wrong Python Version

```bash
# Install correct version with pyenv
pyenv install 3.11.14
pyenv local 3.11.14

# Verify
python --version  # Should show 3.11.14

# Recreate environment
make poetry-clean
make poetry-env-create
```

### Dependencies Out of Sync

```bash
# After git pull, sync dependencies
make poetry-install

# If lock file conflicts, regenerate
poetry lock --no-update
make poetry-install
```

### Virtual Environment Issues

```bash
# Remove and recreate
make poetry-clean
make poetry-env-create

# Check environment location
poetry env info

# List all environments
poetry env list
```

### Package Conflicts

```bash
# Check dependency tree
poetry show --tree

# Check why package is installed
poetry show <package>

# Update lock file
poetry lock --no-update
```

## Best Practices

### Development Workflow

1. **After pulling changes:**
   ```bash
   git pull
   make poetry-install  # Sync dependencies
   ```

2. **Before committing code:**
   ```bash
   make format    # Format code
   make lint      # Check style
   make test      # Run tests
   ```

3. **Adding new dependencies:**
   ```bash
   poetry add <package>      # Adds to pyproject.toml and poetry.lock
   git add pyproject.toml poetry.lock
   git commit -m "Add <package> dependency"
   ```

### Code Quality

- **Always run `make format`** before committing
- **Keep line length to 120 characters** (configured in black/isort)
- **Write tests for new code** in `tests/` directory
- **Document public functions** with docstrings

### Environment Isolation

- **Use `poetry shell`** to activate environment for interactive work
- **Use `poetry run`** for scripts and commands in Makefiles
- **Don't mix pip and poetry** - always use Poetry for installation

### CI/CD

For CI pipelines, use:
```bash
# Install Poetry in CI
pip install poetry

# Install dependencies (no dev tools)
poetry install --no-root --only main

# Or export requirements
poetry export -f requirements.txt --output requirements.txt --without-hashes
pip install -r requirements.txt
```

## Integration with Submodules

Each submodule may have its own `pyproject.toml`:
- **data-platform-etl** - Has its own Poetry setup (3.11.14)
- **bi-airflow-dags** - Has minimal pyproject.toml (just tool configs)
- **data-platform-dagster-group** - Deprecated (ClickHouse, 3.11.9)

**When working in submodules:**
- Use their local Poetry environment
- The workspace root environment is for cross-project work and tooling

## Additional Resources

- [Poetry Documentation](https://python-poetry.org/docs/)
- [pyproject.toml Specification](https://peps.python.org/pep-0621/)
- [Black Code Style](https://black.readthedocs.io/)
- [pytest Documentation](https://docs.pytest.org/)
