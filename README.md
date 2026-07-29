# TCG game logger

Local Flask form for logging Riftbound games into a Neon Postgres database
that Grafana reads from.

## Setup

1. Create the table. In the Neon console SQL Editor, paste the contents
   of `schema.sql` and run it.

2. Install dependencies:

       pip install -r requirements.txt

3. Add your connection string:

       cp .env.example .env

   Open `.env` and paste the connection string from your Neon dashboard
   (Connection Details -> psycopg2). Keep `?sslmode=require` on the end.

4. Run it:

       python app.py

   Open http://localhost:5001

## Notes

- Port 5001, not 5000, to stay clear of AirPlay Receiver on macOS.
- Dropdowns fill themselves from what you've already entered, so spellings
  stay consistent without hardcoding any card lists.
- Logging a Bo3: set a Series ID on game 1 and the shared fields carry over
  to the next game automatically. Leave Series ID blank for Bo1.
- **Never commit `.env`.** It contains your database password.
