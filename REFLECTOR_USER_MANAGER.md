# Reflector User Manager

A unified, menu-driven Bash tool for managing users of an **XLX reflector** — covering the RadioID database, whitelist, dashboard access and password resets from a single interface.

---

## Location

The script must be placed at:

```
/xlxd/users_db/reflector_user_manager.sh
```

Make it executable before first use:

```bash
chmod +x /xlxd/users_db/reflector_user_manager.sh
```

Run it as a user with `sudo` privileges:

```bash
/xlxd/users_db/reflector_user_manager.sh
```

---

## Overview

Instead of running separate scripts for each administrative task, `reflector_user_manager.sh` consolidates everything into a two-level interactive menu that works entirely from the terminal — including over SSH. The interface uses ANSI colors, dynamic terminal-width detection (capped at 70 columns) and a consistent input pattern that prevents accidental data corruption.

---

## File Dependencies

| Purpose | Default path |
|---|---|
| RadioID CSV database | `/xlxd/users_db/users_base.csv` |
| XLX whitelist | `/xlxd/xlxd.whitelist` |
| Dashboard password file | `/var/www/restricted/.htpasswd` |
| Pending password-change list | `/var/www/restricted/pendentes.txt` |
| PHP script to rebuild SQL DB | `/xlxd/users_db/create_user_db.php` |

Paths are defined as variables at the top of the script and can be adjusted if your installation differs.

---

## Menu Structure

```
Main menu
├── 1) Database (RadioID)
│   ├── 1) Add / Edit record
│   ├── 2) Delete record
│   ├── 3) List records by Callsign
│   ├── 4) Search records (filter)
│   ├── 5) Create / Update SQL database
│   └── X) Back
└── 2) Access Control
    ├── 1) Add user       (whitelist + dashboard)
    ├── 2) Reset password (dashboard)
    ├── 3) Remove user    (whitelist + dashboard)
    ├── 4) Look up user   (whitelist + dashboard)
    ├── 5) List pending   (password not yet changed)
    ├── 6) List whitelist (all callsigns)
    └── X) Back
```

---

## Features

### Database — RadioID CSV

#### Add / Edit record
Searches by DMRID or callsign before presenting fields for editing. Pre-filled fields show the current value in brackets — pressing Enter keeps it unchanged. Duplicate DMRID detection prevents conflicts. Supports creating brand-new records as well.

#### Delete record
Looks up the record by DMRID or callsign, displays it in a formatted box for confirmation, then removes it. When a callsign matches multiple records, a numbered list is shown for precise selection.

#### List records by Callsign
Displays all CSV lines that match an exact callsign, numbered for easy reference.

#### Search records (filter)
Filters the database (300 000+ entries) by a chosen field:

| Option | Field searched |
|---|---|
| 1 | Callsign |
| 2 | DMRID |
| 3 | Name (first name + last name simultaneously) |
| 4 | City |
| 5 | Country |

- Matching is **case-insensitive** and **partial** by default — `silva` finds `Silva`, `da Silva`, etc.
- The `*` character works as a wildcard (`curitiba*` → anything starting with "curitiba").
- Results are displayed as a paginated table of **25 records per page** with `[Enter]` / `[P]` / `[X]` navigation.

#### Create / Update SQL database
Calls `php /xlxd/users_db/create_user_db.php` to rebuild the SQL database from the CSV file, keeping the dashboard in sync after bulk edits.

---

### Access Control

#### Add user
Independently asks whether to add the callsign to the **reflector whitelist** and/or the **dashboard** (htpasswd). If the dashboard option is confirmed, a random 12-character password is generated, displayed on screen and added to the pending list so the user is reminded to change it on first login.

#### Reset password
Generates a new random 12-character password for an existing dashboard user, updates htpasswd and adds the callsign back to the pending list.

#### Remove user
Independently removes the callsign from the dashboard and/or the whitelist, with a separate confirmation for each. Also cleans up the pending list automatically.

#### Look up user
Shows the current status of a callsign across three lists:

- Reflector whitelist — **PRESENT** / **ABSENT**
- Dashboard access — **PRESENT** / **ABSENT**
- Pending list — whether the initial password has already been changed

#### List pending (password not yet changed)
Lists every user who has been assigned an initial or reset password but has not yet changed it through the dashboard.

#### List whitelist (all callsigns)
Displays all active (non-commented) entries from `xlxd.whitelist` sorted alphabetically and arranged in **auto-sized columns** that adapt to the terminal width.

---

## Input Conventions

| Input | Effect |
|---|---|
| `X` | Cancels the current operation and returns to the previous menu |
| `-` | Clears the DMRID field of a record (DMRID field only) |
| `Enter` on a `[current: …]` field | Keeps the existing value unchanged |
| `y` / `Y` | Confirms a prompt |
| `N` or Enter | Declines a prompt |

---

## Requirements

- Bash 4.0 or later (`mapfile`, `^^` case modifier)
- `awk`, `sed`, `grep`, `tput` (standard on any Linux server)
- `apache2-utils` for `htpasswd`
- `php-cli` for the SQL rebuild feature
- `sudo` access for writing to protected paths
