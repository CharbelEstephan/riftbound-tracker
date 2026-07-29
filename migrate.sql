-- Run this ONLY if you already created the old games table.
-- It throws away existing rows - fine if you haven't logged real games yet.
-- If you have games you want to keep, tell Claude and we'll write a
-- non-destructive migration instead.

DROP VIEW IF EXISTS game_domains;
DROP TABLE IF EXISTS games;

-- Now run the contents of schema.sql.
