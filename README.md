# README

Pokévelocity is a gamified productivity app that turns software development into a Pokémon-catching adventure. Complete your Jira tickets,
earn Pokéballs based on story points, and use them to catch all 151 original Pokémon as you adventure through Kanto. The harder your tickets and the faster your velocity, the more and better Pokéballs you'll earn
giving you higher catch rates and changes for rare and legendary Pokémon. Track your progress in your Pokédex, gather gym badges, compete on the leaderboard with teammates, and prove you can truly code 'em all. Built for development teams who want to add a fun, nostalgic twist to sprint
velocity tracking.

Upon spin up, the user activation code will be PALLET but you're encouraged to change that to a different 6 character string immediately

## Running the App

### Option 1: Docker Compose (Recommended for Easy Setup)

The easiest way to get started is with Docker Compose, which will set up everything for you (make sure you have Docker daemon running):

```bash
docker compose up
```

This will:
- Start a PostgreSQL database
- Build and start the Rails application
- Create the database and load the schema
- Seed the database with all 151 Pokémon, routes, and the PALLET activation code
- Make the app available at http://localhost:3000

To stop the app, press `Ctrl+C` or run:
```bash
docker compose down
```

To completely remove all data and start fresh:
```bash
docker compose down -v
```

### Option 2: Local Development

If you prefer to run the app locally without Docker:

1. Install PostgreSQL
2. Install Ruby 3.3.6
3. Install dependencies: `bundle install`
4. Set up the database: `rails db:setup`
5. Run the server: `rails server`

**Note:** This is an unofficial fan project and isn’t associated with Nintendo or The Pokémon Company in any way. 
It’s simply my way of celebrating the nostalgia I have for the original Pokemon games and sharing something fun with the developer community. 
This project is strictly and entirely non-commercial — I haven’t, can’t, and won’t accept any form of payment for it.