import os
from collections import Counter, defaultdict
from datetime import date

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
from flask import Flask, redirect, render_template, request, url_for

import options

load_dotenv()

app = Flask(__name__)

DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    raise SystemExit(
        "DATABASE_URL is not set. Create a .env file containing one line:\n"
        "DATABASE_URL=<your Neon connection string>"
    )


def get_conn():
    return psycopg2.connect(DATABASE_URL)


def get_legend_domains():
    """Build a legend -> [domain_1, domain_2] map from what you've logged.

    Every game records a legend next to its domains, on both sides of the
    table, so the mapping is already sitting in your own data. Nothing
    hardcoded means nothing to go stale when a set drops. If a legend has been
    logged with two different pairings (a typo, most likely), the most
    frequent one wins.
    """
    pairs = defaultdict(Counter)
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT my_leader,  my_domain_1,  my_domain_2  FROM games
                UNION ALL
                SELECT opp_leader, opp_domain_1, opp_domain_2 FROM games
                """
            )
            for leader, d1, d2 in cur.fetchall():
                if leader and d1:
                    pairs[leader][(d1, d2)] += 1
    return {
        leader: list(c.most_common(1)[0][0])
        for leader, c in pairs.items()
    }


def get_distinct(column):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"SELECT DISTINCT {column} FROM games "
                f"WHERE {column} IS NOT NULL AND {column} <> '' ORDER BY {column}"
            )
            return [r[0] for r in cur.fetchall()]


def get_next_series_id():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COALESCE(MAX(series_id), 0) + 1 FROM games")
            return cur.fetchone()[0]


def get_recent(limit=15):
    with get_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute(
                "SELECT * FROM games ORDER BY played_on DESC, id DESC LIMIT %s",
                (limit,),
            )
            return cur.fetchall()


def get_record():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) FILTER (WHERE won), "
                "       COUNT(*) FILTER (WHERE NOT won) FROM games"
            )
            wins, losses = cur.fetchone()
    return wins or 0, losses or 0


def blank_to_none(value):
    value = (value or "").strip()
    return value or None


@app.route("/")
def index():
    wins, losses = get_record()
    total = wins + losses

    # Anything you've typed that isn't in options.py still shows up, so a
    # legend from a brand new set works before you get round to editing it.
    known_legends = set(options.LEGENDS)
    for col in ("my_leader", "opp_leader"):
        known_legends.update(get_distinct(col))

    known_events = sorted(set(options.EVENT_TYPES) | set(get_distinct("event_type")))

    return render_template(
        "index.html",
        legends=sorted(known_legends),
        domains=options.DOMAINS,
        events=known_events,
        locations=get_distinct("location"),
        decks=get_distinct("my_deck"),
        opponents=get_distinct("opponent"),
        legend_domains=get_legend_domains(),
        recent=get_recent(),
        next_series=get_next_series_id(),
        today=date.today().isoformat(),
        wins=wins,
        losses=losses,
        winrate=round(100 * wins / total, 1) if total else None,
        carry={k: request.args.get(k, "") for k in
               ["played_on", "series_id", "event_type", "location",
                "my_leader", "my_domain_1", "my_domain_2", "my_deck",
                "opponent", "opp_leader", "opp_domain_1", "opp_domain_2"]},
    )


def clean_domains(d1, d2):
    """Store domains in the order they're printed on the card - domain_1 is
    whatever comes first. The my_colors / opp_colors generated columns
    normalise the pair alphabetically for grouping, so matchup stats stay
    consistent even if two legends print the same pair in opposite orders."""
    d1 = (d1 or "").strip()
    d2 = (d2 or "").strip()
    return (d1, d2 or None)



@app.route("/add", methods=["POST"])
def add():
    f = request.form

    my_d1, my_d2 = clean_domains(f.get("my_domain_1"), f.get("my_domain_2"))
    opp_d1, opp_d2 = clean_domains(f.get("opp_domain_1"), f.get("opp_domain_2"))

    went_first = f.get("went_first")
    went_first = None if went_first == "" else (went_first == "true")

    row = (
        f["played_on"],
        blank_to_none(f.get("series_id")),
        blank_to_none(f.get("game_in_series")),
        f["event_type"].strip(),
        blank_to_none(f.get("location")),
        f["my_leader"].strip(),
        my_d1,
        my_d2,
        blank_to_none(f.get("my_deck")),
        blank_to_none(f.get("opponent")),
        f["opp_leader"].strip(),
        opp_d1,
        opp_d2,
        went_first,
        f["won"] == "true",
        blank_to_none(f.get("notes")),
    )

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO games
                    (played_on, series_id, game_in_series, event_type, location,
                     my_leader, my_domain_1, my_domain_2, my_deck, opponent,
                     opp_leader, opp_domain_1, opp_domain_2,
                     went_first, won, notes)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                row,
            )

    if f.get("series_id"):
        return redirect(url_for(
            "index",
            played_on=f["played_on"],
            series_id=f["series_id"],
            event_type=f["event_type"],
            location=f.get("location", ""),
            my_leader=f["my_leader"],
            my_domain_1=my_d1,
            my_domain_2=my_d2 or "",
            my_deck=f.get("my_deck", ""),
            opponent=f.get("opponent", ""),
            opp_leader=f["opp_leader"],
            opp_domain_1=opp_d1,
            opp_domain_2=opp_d2 or "",
        ))

    return redirect(url_for("index"))


@app.route("/delete/<int:game_id>", methods=["POST"])
def delete(game_id):
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM games WHERE id = %s", (game_id,))
    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(debug=True, port=5001)
