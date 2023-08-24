CREATE user axolotl WITH ENCRYPTED PASSWORD 'password';
CREATE DATABASE axldb;
GRANT all privileges ON DATABASE axldb TO axolotl;

\c axldb axolotl

DROP TABLE IF EXISTS sessions_items;
DROP TABLE IF EXISTS sessions;
DROP INDEX IF EXISTS logs_plt_idx;
DROP INDEX IF EXISTS logs_slt_idx;
DROP TABLE IF EXISTS logs;
DROP TABLE IF EXISTS patches;
DROP TABLE IF EXISTS generalizations;
DROP TABLE IF EXISTS snapshots;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS applications;

CREATE TABLE IF NOT EXISTS applications (
    application_id SERIAL PRIMARY KEY,
    application VARCHAR(255) NOT NULL UNIQUE,
    language VARCHAR(31) NOT NULL,   -- "py", "java" or "cs"
    repository VARCHAR(255),         -- "https://gitlab.com/revdebug/python/axolotl/axolotl.git"
    subdir VARCHAR(255),
    username VARCHAR(255),
    password VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS locations (
    location_id SERIAL PRIMARY KEY,
    application_id INT NOT NULL,
    location VARCHAR(63) NOT NULL,   -- "hash:lasti" or just "hash" - (e.g. "cVVk3c5Xd6Nnqs60_-nzIC:266")
    name VARCHAR(255) NOT NULL,      -- "file.py:funclineno:funccol:funcname:hash:lineno:col:lasti" or just "file.py:funclineno:funccol:funcname:hash" - (e.g. "t2.py:12:1:level2:cVVk3c5Xd6Nnqs60_-nzIC:17:1:266")
    CONSTRAINT fk_application FOREIGN KEY(application_id) REFERENCES applications(application_id) ON DELETE CASCADE,
    UNIQUE(application_id, location)
);

CREATE TABLE IF NOT EXISTS snapshots (
    snapshot_id SERIAL PRIMARY KEY,
    location_id INT NOT NULL,
    ts BIGINT NOT NULL,              -- nanoseconds since the epoch
    langver VARCHAR(31) NOT NULL,    -- "3.10.2"
    release VARCHAR(40),             -- git hash
    hash CHAR(40) NOT NULL,          -- "55aecdf485ad2c7f0aa09bbe909cc68d1b524439" - of object invariants
    isexc BOOLEAN NOT NULL,          -- means original exception which marked location for future snapshots, snapshot not comparable to snapshots at this location once marked for snapshots, does not mean same as if 'error' is present
    isroot BOOLEAN,                  -- whether base frame is the root source of the exception instead of excluded system code below, only valid if 'error' present
    error VARCHAR(255),              -- "ValueError" or null
    detail TEXT,                     -- "ValueError: expecting an integer" or null
    traceback TEXT,                  -- "Traceback (most recent call last):\n ... \nValueError: expecting an integer" or null
    snapshot TEXT NOT NULL,          -- ([frame id, ...], [serialized obj, ...])
    extra TEXT,                      -- language specific stuff
    CONSTRAINT fk_location FOREIGN KEY(location_id) REFERENCES locations(location_id) ON DELETE CASCADE,
    UNIQUE(location_id, hash)
);

CREATE TABLE IF NOT EXISTS generalizations (
    generalization_id SERIAL PRIMARY KEY,
    key CHAR(40) NOT NULL UNIQUE,    -- hash of something like "1g2g3g4d5d6" or "5g6d1d2d3d4" + rules string
    location_id INT NOT NULL,
    ts BIGINT NOT NULL,              -- for periodic cleaning
    generalization TEXT NOT NULL,
    CONSTRAINT fk_location FOREIGN KEY(location_id) REFERENCES locations(location_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS patches (
    patch_id SERIAL PRIMARY KEY,
    location_id INT NOT NULL UNIQUE,
    patch TEXT NOT NULL,
    extra TEXT,                      -- language specific stuff
    CONSTRAINT fk_location FOREIGN KEY(location_id) REFERENCES locations(location_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS logs (
    log_id SERIAL PRIMARY KEY,
    scope_loc_id INT NOT NULL,       -- for getting by execution in function or file, etc...
    patch_loc_id INT,                -- for getting by execution in patch
    ts BIGINT NOT NULL,
    langver VARCHAR(31) NOT NULL,    -- "3.10.2"
    release VARCHAR(40),             -- git hash
    text TEXT,
    object TEXT,
    CONSTRAINT fk_scope_loc FOREIGN KEY(scope_loc_id) REFERENCES locations(location_id) ON DELETE CASCADE,
    CONSTRAINT fk_patch_loc FOREIGN KEY(patch_loc_id) REFERENCES locations(location_id) ON DELETE CASCADE
);

CREATE INDEX logs_slt_idx ON logs(scope_loc_id, ts);
CREATE INDEX logs_plt_idx ON logs(patch_loc_id, ts);

CREATE TABLE IF NOT EXISTS sessions (
    session_id SERIAL PRIMARY KEY,
    ts BIGINT NOT NULL               -- for periodic cleaning of stale sessions
);

CREATE TABLE IF NOT EXISTS session_items (
    session_id INT NOT NULL,
    key VARCHAR(255) NOT NULL,
    value TEXT,
    CONSTRAINT fk_session FOREIGN KEY(session_id) REFERENCES sessions(session_id) ON DELETE CASCADE,
    UNIQUE(session_id, key)
);
