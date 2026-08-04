-- Riftbound game log schema.
--
-- Domains are stored as two separate columns per side so you can ask
-- "how often do I play Mind?" without string matching. The combined pair
-- (e.g. 'Fury/Chaos') is a GENERATED column - Postgres computes it from the
-- two parts, so it can never disagree with them.
--
-- Domains are stored alphabetically by the app, so Fury/Chaos and Chaos/Fury
-- can't both exist.

CREATE TABLE games (
    id             SERIAL PRIMARY KEY,
    played_on      DATE NOT NULL,
    series_id      INT,
    game_in_series INT,
    event_type     TEXT NOT NULL,
    location       TEXT,

    my_leader      TEXT NOT NULL,
    my_domain_1    TEXT NOT NULL,
    my_domain_2    TEXT,
    my_colors      TEXT GENERATED ALWAYS AS (
                       my_domain_1 || CASE WHEN my_domain_2 IS NULL
                                           THEN '' ELSE '/' || my_domain_2 END
                   ) STORED,
    my_deck        TEXT,

    opponent       TEXT,
    opp_leader     TEXT NOT NULL,
    opp_domain_1   TEXT NOT NULL,
    opp_domain_2   TEXT,
    opp_colors     TEXT GENERATED ALWAYS AS (
                       opp_domain_1 || CASE WHEN opp_domain_2 IS NULL
                                            THEN '' ELSE '/' || opp_domain_2 END
                   ) STORED,

    went_first     BOOLEAN,
    won            BOOLEAN NOT NULL,
    notes          TEXT
);

CREATE INDEX idx_games_played_on ON games (played_on);

-- One row per domain per side per game. Makes per-domain questions trivial:
--   SELECT domain, COUNT(*) FROM game_domains WHERE side = 'me' GROUP BY 1;
--   SELECT domain,
--          ROUND(100.0 * COUNT(*) FILTER (WHERE won) / COUNT(*), 1) AS winrate
--   FROM game_domains WHERE side = 'me' GROUP BY 1;
CREATE VIEW game_domains AS
    SELECT id, played_on, event_type, won, 'me'   AS side, my_leader  AS leader, my_domain_1  AS domain FROM games
    UNION ALL
    SELECT id, played_on, event_type, won, 'me',           my_leader,            my_domain_2         FROM games WHERE my_domain_2 IS NOT NULL
    UNION ALL
    SELECT id, played_on, event_type, won, 'them',         opp_leader,           opp_domain_1        FROM games
    UNION ALL
    SELECT id, played_on, event_type, won, 'them',         opp_leader,           opp_domain_2        FROM games WHERE opp_domain_2 IS NOT NULL;


-- Pack-opening / pull-rate log. Independent of games; one row per acquisition
-- event (a pack, a sleeve, a vault, etc.). Each hit_* column counts how many
-- of that hit type came out of the packs in this row.
CREATE TABLE openings (
    id            SERIAL PRIMARY KEY,
    acquired_on   DATE NOT NULL,
    product       TEXT NOT NULL,
    quantity      INT NOT NULL,
    set_name      TEXT NOT NULL,
    is_pity       BOOLEAN DEFAULT FALSE,
    hit_rare        INT NOT NULL DEFAULT 0,
    hit_leader      INT NOT NULL DEFAULT 0,
    hit_dbl_leader  INT NOT NULL DEFAULT 0,
    hit_epic        INT NOT NULL DEFAULT 0,
    hit_fa_rune     INT NOT NULL DEFAULT 0,
    hit_alt_art     INT NOT NULL DEFAULT 0,
    hit_overnumber  INT NOT NULL DEFAULT 0,
    hit_signature   INT NOT NULL DEFAULT 0,
    hit_sig_spell   INT NOT NULL DEFAULT 0,
    hit_sp_rare     INT NOT NULL DEFAULT 0,
    hit_ultimate    INT NOT NULL DEFAULT 0,
    hit_nn_chase    INT NOT NULL DEFAULT 0,
    location      TEXT,
    opened_by     TEXT,
    notes         TEXT
);

CREATE INDEX idx_openings_acquired_on ON openings (acquired_on);


-- Booster-box hit log. Kept as its own table (not mixed into openings) so box
-- hits and loose-pack pulls stay separate metrics for the dashboard. Product
-- is always a booster box, so there's no product column; no pity concept here.
-- One row per box-opening event; hit_* columns count that type across the row.
CREATE TABLE boxes (
    id            SERIAL PRIMARY KEY,
    opened_on     DATE NOT NULL,
    quantity      INT NOT NULL,
    set_name      TEXT NOT NULL,
    hit_rare        INT NOT NULL DEFAULT 0,
    hit_leader      INT NOT NULL DEFAULT 0,
    hit_dbl_leader  INT NOT NULL DEFAULT 0,
    hit_epic        INT NOT NULL DEFAULT 0,
    hit_fa_rune     INT NOT NULL DEFAULT 0,
    hit_alt_art     INT NOT NULL DEFAULT 0,
    hit_overnumber  INT NOT NULL DEFAULT 0,
    hit_signature   INT NOT NULL DEFAULT 0,
    hit_sig_spell   INT NOT NULL DEFAULT 0,
    hit_sp_rare     INT NOT NULL DEFAULT 0,
    hit_ultimate    INT NOT NULL DEFAULT 0,
    hit_nn_chase    INT NOT NULL DEFAULT 0,
    location      TEXT,
    notes         TEXT
);

CREATE INDEX idx_boxes_opened_on ON boxes (opened_on);


-- Individual card names for premium pulls, so a specific hit can be looked up
-- later (e.g. in Grafana's chase log). One row per named card. The count
-- columns on openings/boxes still drive the rates; these tables just attach
-- names. ON DELETE CASCADE keeps them in step when a parent row is deleted.
--
-- Pulls name Alt Art, SP Rare, Overnumber, Signature, Ultimate, Nexus Night
-- Chase; boxes name SP Rare, Overnumber, Signature, Ultimate. rarity holds the
-- display label (e.g. 'Signature').
CREATE TABLE opening_cards (
    id          SERIAL PRIMARY KEY,
    opening_id  INT  NOT NULL REFERENCES openings(id) ON DELETE CASCADE,
    rarity      TEXT NOT NULL,
    card_name   TEXT NOT NULL
);

CREATE INDEX idx_opening_cards_opening ON opening_cards (opening_id);

CREATE TABLE box_cards (
    id          SERIAL PRIMARY KEY,
    box_id      INT  NOT NULL REFERENCES boxes(id) ON DELETE CASCADE,
    rarity      TEXT NOT NULL,
    card_name   TEXT NOT NULL
);

CREATE INDEX idx_box_cards_box ON box_cards (box_id);
