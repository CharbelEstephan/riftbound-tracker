-- Adds: (1) who opened/bought a pack for you, and (2) per-card name capture
-- for premium pulls on both the Pulls and Box Hits tabs.
-- Non-destructive. Run this once against your Neon database.

-- 1. "Opened / bought for me" on the Pulls tab.
ALTER TABLE openings ADD COLUMN IF NOT EXISTS opened_by TEXT;

-- 2. Individual card names for premium pulls (Pulls tab: Alt Art, SP Rare,
--    Overnumber, Signature, Ultimate, Nexus Night Chase). One row per card.
CREATE TABLE IF NOT EXISTS opening_cards (
    id          SERIAL PRIMARY KEY,
    opening_id  INT  NOT NULL REFERENCES openings(id) ON DELETE CASCADE,
    rarity      TEXT NOT NULL,
    card_name   TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_opening_cards_opening ON opening_cards (opening_id);

-- 2B. Same for booster boxes (Box Hits tab: SP Rare, Overnumber, Signature,
--     Ultimate).
CREATE TABLE IF NOT EXISTS box_cards (
    id          SERIAL PRIMARY KEY,
    box_id      INT  NOT NULL REFERENCES boxes(id) ON DELETE CASCADE,
    rarity      TEXT NOT NULL,
    card_name   TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_box_cards_box ON box_cards (box_id);
