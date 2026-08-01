-- Adds the "SP Rare" hit type to both hit-tracking tables.
-- Non-destructive: only adds a column (defaulting to 0) to each table.
-- Run this once against your Neon database.

ALTER TABLE openings ADD COLUMN hit_sp_rare INT NOT NULL DEFAULT 0;
ALTER TABLE boxes    ADD COLUMN hit_sp_rare INT NOT NULL DEFAULT 0;
