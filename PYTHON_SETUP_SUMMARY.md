# Python Environment Setup - Summary

This document summarizes the unified Poetry setup created for the MRGE Data Team workspace.

## What Was Created

### 1. Core Configuration Files

#### `pyproject.toml`
- **Purpose:** Main Poetry configuration with unified dependencies
- **Contents:**
  - Python 3.11.14 requirement
  - Dependencies from `data-platform-etl` (Airflow, dbt, Databricks, Polars, etc.)
  - Dev dependencies (pytest, black, isort, mypy, pylint)
  - Tool configurations (black, isort, pytest, mypy, pylint, bandit)
- **Key Features:**
  - 120 character line length
  - Black-compatible isort profile
  - Pytest with coverage reporting
  - Lenient mypy settings for gradual adoption

#### `poetry.toml`
- **Purpose:** Poetry behavior configuration
- **Contents:**
  - Creates `.venv/` in project directory (not global cache)
  - Uses active Python version
  - Isolated from system packages

#### `.python-version`
- **Purpose:** Specify required Python version
- **Contents:** `3.11.14`
- **Used by:** pyenv, Poetry, IDEs

#### `.pre-commit-config.yaml`
- **Purpose:** Automated code quality checks on git commit
- **Hooks:**
  - File checks (trailing whitespace, YAML/JSON/TOML syntax)
  - Black formatting
  - isort import sorting
  - flake8 linting
  - Bandit security checks
- **Usage:** `make pre-commit-install` then commits auto-format

### 2. Makefile Enhancements

Added **20+ new commands** organized into categories:

#### Environment Management (9 commands)
- `poetry-env-create` - Full setup from scratch
- `poetry-install` - Sync dependencies from lock
- `poetry-install-dev` - Install with dev tools
- `poetry-env-update` - Update to latest versions
- `poetry-lock` - Update lock file only
- `poetry-export` - Generate requirements.txt
- `poetry-check` - Validate configuration
- `poetry-env-info` - Show environment details
- `poetry-clean` - Remove cache and venvs

#### Code Quality (7 commands)
- `test` - Run pytest
- `lint` - Check code style
- `format` - Auto-format code
- `typecheck` - Run mypy
- `pre-commit-install` - Install git hooks
- `pre-commit-run` - Run all hooks
- `check-all` - Run all checks

#### Development (2 commands)
- `jupyter` - Start Jupyter Lab
- `ipython` - Start IPython

#### Help
- `help` - Show all commands (also default target)

### 3. Documentation

#### `PYTHON_ENV_GUIDE.md`
- **Purpose:** Comprehensive user guide for Python environment
- **Contents:**
  - Quick start instructions
  - Makefile command reference
  - Dependency management guide
  - Configuration explanations
  - Troubleshooting section
  - Best practices
  - CI/CD integration tips

#### `README.md` (updated)
- Added Python environment setup section
- Documented Makefile commands
- Added code quality tools section
- Included Python version requirements

### 4. Testing Infrastructure

#### `tests/test_environment.py`
- Sample tests to verify setup
- Tests for Python version, imports, basic functionality
- Can run immediately after setup

#### `tests/conftest.py`
- pytest configuration
- Sample fixtures (sample_data, temp_env_vars)
- Automatically loaded by pytest

### 5. .gitignore Updates

Added Poetry-specific exclusions:
- `poetry.lock` (too noisy for collaboration)
- `.poetry/`
- `requirements.txt` (generated files)
- Coverage reports
- Cache directories

## Quick Start

```bash
# 1. Create environment
make poetry-env-create

# 2. Activate environment
poetry shell

# 3. Verify setup
make poetry-env-info

# 4. (Optional) Install pre-commit hooks
make pre-commit-install

# 5. (Optional) Run tests
make test
```

## Dependency Sources

The unified `pyproject.toml` consolidates dependencies from:

### From data-platform-etl
- **Airflow ecosystem:**
  - apache-airflow 2.10.3 (with Kubernetes extras)
  - apache-airflow-providers-databricks 7.6+
  - apache-airflow-providers-amazon 9.15+
  - apache-airflow-providers-slack 9.2+
  - astronomer-cosmos 1.11+

- **dbt:**
  - dbt-core 1.10.6
  - dbt-databricks 1.10.6+
  - dbt-redshift 1.9.5+

- **Data processing:**
  - polars 1.32+ (high-performance DataFrame library)
  - pandas 2.1.4
  - duckdb 1.3.2+

- **Cloud/Infrastructure:**
  - boto3 1.34+
  - s3fs 2025.7.0
  - databricks-sdk 0.47

- **Utilities:**
  - jinja2, pyyaml, typer, requests, graphviz
  - opsgenie-sdk (alerting)
  - yfinance, pycountry, babel (data sources)

### Additional for Development
- Testing: pytest, pytest-cov, pytest-mock
- Linting: black, isort, flake8, mypy, pylint
- Tools: pre-commit, ipykernel, jupyter
- Docs: mkdocs, mkdocs-material

## Key Design Decisions

### 1. Python Version: 3.11.14
- **Why:** Matches `data-platform-etl` (active repo)
- **Note:** `data-platform-dagster-group` uses 3.11.9 but is deprecated

### 2. Package Mode: False
- **Why:** This is a workspace, not a distributable package
- **Effect:** No `__init__.py` or package installation needed

### 3. In-Project Virtual Environments
- **Why:** Easier discovery, IDE integration, cleanup
- **Location:** `.venv/` in workspace root
- **Alternative:** Global cache at `~/.cache/pypoetry/virtualenvs/`

### 4. No poetry.lock in Git
- **Why:** Lock file can cause merge conflicts in collaborative repos
- **Effect:** Each developer gets latest compatible versions
- **Trade-off:** Slight version drift possible (mitigated by version constraints)

### 5. Export requirements.txt
- **Why:** Some environments don't support Poetry (Docker, MWAA)
- **Command:** `make poetry-export`
- **Files:** `requirements.txt` (prod) + `requirements-dev.txt` (all)

### 6. 120 Character Line Length
- **Why:** Balances readability with modern wide screens
- **Tools:** Enforced by black, isort, flake8, pylint

### 7. Lenient Type Checking
- **Why:** Gradual adoption—don't block contributions
- **Config:** `disallow_untyped_defs = false`, `ignore_missing_imports = true`
- **Future:** Can be tightened as type hints are added

## Maintenance Workflows

### After git pull
```bash
git pull
make poetry-install  # Sync dependencies from updated pyproject.toml
```

### Before committing
```bash
make format          # Auto-format code
make lint            # Check style
make test            # Run tests
# Or use pre-commit hooks (auto-runs on commit)
```

### Adding a new dependency
```bash
poetry add <package>
# This updates pyproject.toml (tracked in git)
# poetry.lock is not tracked, so no conflict on pull
```

### Updating dependencies
```bash
make poetry-env-update  # Update all to latest compatible versions
```

### Exporting for deployment
```bash
make poetry-export      # Creates requirements.txt for Docker/MWAA
```

## Integration with Submodules

### data-platform-etl
- **Has its own Poetry setup** (pyproject.toml with same dependencies)
- **When working there:** Use its local environment
- **When working in workspace:** Use workspace environment

### bi-airflow-dags
- **Has minimal pyproject.toml** (just tool configs)
- **No Poetry dependencies** (mainly DAG definitions)

### data-platform-dagster-group
- **Deprecated** (uses ClickHouse, Python 3.11.9)
- **Keep for reference only**
- **Don't use its environment**

### data-platform-infra
- **No Python dependencies** (Terraform only)
- **No pyproject.toml needed**

## CI/CD Usage

### GitLab CI Example

```yaml
image: python:3.11.14

before_script:
  - pip install poetry
  - poetry config virtualenvs.in-project true
  - poetry install --no-root

stages:
  - lint
  - test

lint:
  stage: lint
  script:
    - make lint
    - make typecheck

test:
  stage: test
  script:
    - make test
  coverage: '/TOTAL.*\s+(\d+%)$/'
```

### Or use requirements.txt

```yaml
before_script:
  - pip install poetry
  - poetry export -f requirements.txt -o requirements.txt --without-hashes
  - pip install -r requirements.txt

test:
  script:
    - pytest
```

## Troubleshooting

### Common Issues

1. **"Poetry not found"**
   - Run: `make poetry-install-tool`
   - Or: `curl -sSL https://install.python-poetry.org | python3 -`
   - Add to PATH: `export PATH="$HOME/.local/bin:$PATH"`

2. **"Wrong Python version"**
   - Install: `pyenv install 3.11.14`
   - Set local: `pyenv local 3.11.14`
   - Recreate: `make poetry-clean && make poetry-env-create`

3. **"Dependencies out of sync"**
   - Run: `make poetry-install`
   - If lock conflicts: `poetry lock --no-update`

4. **"Pre-commit hooks failing"**
   - Auto-fix: `make format`
   - Check what failed: `make lint`
   - Skip (emergency): `git commit --no-verify`

### Getting Help

```bash
# Check environment
make poetry-env-info

# Validate configuration
make poetry-check

# Show dependency tree
poetry show --tree

# Check outdated packages
poetry show --outdated

# Full command list
make help
```

## Files Created/Modified

### Created
- ✅ `pyproject.toml` - Main Poetry configuration
- ✅ `poetry.toml` - Poetry behavior settings
- ✅ `.python-version` - Python version spec
- ✅ `.pre-commit-config.yaml` - Git hooks configuration
- ✅ `PYTHON_ENV_GUIDE.md` - User guide
- ✅ `tests/test_environment.py` - Sample tests
- ✅ `tests/conftest.py` - pytest configuration
- ✅ `tests/` - Test directory

### Modified
- ✅ `Makefile` - Added 20+ commands
- ✅ `README.md` - Added Python environment section
- ✅ `.gitignore` - Added Poetry exclusions

## Next Steps

### For Users
1. Run `make poetry-env-create` to set up environment
2. Run `poetry shell` to activate
3. Run `make help` to see available commands
4. Read `PYTHON_ENV_GUIDE.md` for detailed usage

### For Maintainers
1. Keep `pyproject.toml` in sync with `data-platform-etl`
2. Update dependencies periodically: `make poetry-env-update`
3. Export requirements for Docker/MWAA: `make poetry-export`
4. Communicate dependency changes to team

### Optional Enhancements
- Add GitHub Actions / GitLab CI configuration
- Create Docker image with Poetry pre-installed
- Add more pytest fixtures in `conftest.py`
- Create Jupyter notebook templates
- Add dbt project templates
- Set up mkdocs for documentation site
