# Scripts

Utility scripts for maintaining Bay Navigator.

## generate-api.js

**Purpose:** Generates static JSON API files from YAML program data.

**Usage:**
```bash
node scripts/generate-api.js
```

**When to use:**
- Runs automatically via GitHub Actions when `_data/programs/` changes
- Can be run manually to preview API changes locally

**Features:**
- Reads all YAML files in `_data/programs/`
- Generates individual program JSON files in `api/programs/`
- Generates category and eligibility indexes
- Generates full programs list

**Output:**
Static JSON files in the `api/` directory that are served alongside the Jekyll site.

---

## add_verification_dates.py

**Purpose:** Bulk add or update `verified_date` field in YAML files.

**Usage:**
```bash
python3 scripts/add_verification_dates.py
```

**When to use:**
- After bulk verification of programs
- When updating verification dates for all programs
- Data cleanup tasks

**Note:** This modifies YAML files directly. Review changes with `git diff` before committing.

---

## Other Scripts

- `convert-banner.js` - Utility for converting banner images
- `cleanup-deployments.sh` - Cleans up old GitHub deployments
- `sync-github-ips.sh` - Syncs GitHub IP ranges for security
- `update-git-date.sh` - Updates git commit dates

---

## License

These scripts are part of Bay Navigator and licensed under MIT.
See [LICENSE](../LICENSE) for details.
