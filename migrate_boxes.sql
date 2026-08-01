-- Adds the booster-box hit tracker table to an existing database.
-- Non-destructive: only creates a new table, touches nothing else.
-- Run this once against your Neon database.

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
