-- Initial Schema for poolio

BEGIN;
    CREATE SCHEMA IF NOT EXISTS poolio;

    SET search_path TO poolio, public;

    -- Table which holds information related to a team which is participating in the pool.
    --
    -- COLUMNS
    -- pool_team_id: (PK) ID of the pool team
    -- team_name:    Name of the pool team
    -- points:       Total number of points that the team has (Denormalized to easily rank teams, audited nightly)
    -- logo:         URL to the image of the team logo
    -- cr_date:      Timestamp of when the record was added
    --
    CREATE TABLE pool_teams (
        pool_team_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        team_name    VARCHAR(30) UNIQUE NOT NULL,
        points       SMALLINT DEFAULT 0 NOT NULL CHECK (points >= 0),
        logo         TEXT,
        cr_date      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
        upd_date     TIMESTAMPTZ
    );

    -- Create trigger to update the pool_teams.upd_date field when pool_teams is updated
    CREATE FUNCTION update_pool_team_upd_date()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.upd_date = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER t_update_pool_team
    BEFORE UPDATE ON pool_teams
    FOR EACH ROW
    EXECUTE FUNCTION update_pool_team_upd_date();

    -- Enum which holds the available leagues (only NHL for the time being, possibly added to later)
    CREATE TYPE LEAGUE AS ENUM ('NHL');

    -- Table which holds information related to a sports team that made the playoffs
    -- The table name is generic, i.e not nhl_teams, in case I want to create pools for other leagues like the world cup or MLB playoffs
    --
    -- COLUMNS
    -- team_id:      (PK) ID of the team
    -- espn_team_id: ID from the ESPN system which references this team in their database
    -- league:       The league that the team plays in
    -- region:       Region where the team is from (i.e Ottawa, Carolina)
    -- nickname:     Nickname of the team (i.e Senators, Hurricanes)
    -- abbr:         Team abbreviation (i.e OTT, CAR)
    -- logo:         URL to the image of the team logo
    -- eliminated:   Boolean whether the team has been eliminated from the playoffs or not
    --
    CREATE TABLE teams (
        team_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        espn_team_id INT NOT NULL,
        league       LEAGUE NOT NULL DEFAULT 'NHL',
        region       TEXT NOT NULL,
        nickname     TEXT NOT NULL,
        abbr         VARCHAR(3) NOT NULL,
        logo         TEXT NOT NULL,
        eliminated   BOOL DEFAULT false NOT NULL,
        UNIQUE (league, espn_team_id) -- ESPN's IDs are league-specific
    );

    -- Enum which holds the player classifications: 'F' - Forward, 'D' - Defense, 'G' - Goalie
    CREATE TYPE PLAYER_CLASS AS ENUM ('F', 'D', 'G');

    -- Table which holds information related to players who have been selected in the pool
    --
    -- COLUMNS
    -- player_id:      (PK) ID of the player
    -- pool_team_id:   (FK) ID of the pool team which this player is a member of
    -- team_id:        (FK) ID of the sports team which this player is a member of
    -- espn_player_id: ID from the ESPN system which references this player in their database
    -- league:         The league that the player plays in
    -- first_name:     The player's first name
    -- last_name:      The player's last name
    -- classification: Whether the player is a Forward, Defenseman, or Goalie
    --
    CREATE TABLE players (
        player_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        pool_team_id   INT REFERENCES pool_teams (pool_team_id) NOT NULL,
        team_id        INT REFERENCES teams (team_id) NOT NULL,
        espn_player_id INT UNIQUE NOT NULL,
        league         LEAGUE NOT NULL DEFAULT 'NHL',
        first_name     TEXT NOT NULL,
        last_name      TEXT NOT NULL,
        classification PLAYER_CLASS NOT NULL,
        UNIQUE (league, espn_player_id) -- ESPN's IDs are league-specific
    );

    -- Table which represents a playoff series between two of the teams, and holds information on whether the series is complete and how many wins are required to win the series
    --
    -- COLUMNS
    -- series_id:         (PK) ID of the series
    -- complete:          Boolean whether the series is complete
    -- num_wins_required: The number of games a team needs to win to win the series
    CREATE TABLE series (
        series_id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        complete          BOOL DEFAULT false NOT NULL,
        num_wins_required SMALLINT DEFAULT 4 NOT NULL CHECK (num_wins_required > 0)
    );

    -- Table which links a team to a specific series, and holds information on how many wins they have in that series
    --
    -- COLUMNS
    -- team_id:   (FK) ID of the team participating in the series
    -- series_id: (FK) ID of the series that the team is participating in
    -- wins:      Number of wins that the team has in the series
    -- upd_date:  Timestamp of when the record was updated last
    --
    CREATE TABLE series_teams (
        team_id   INT REFERENCES teams (team_id) NOT NULL,
        series_id INT REFERENCES series (series_id) NOT NULL,
        wins      SMALLINT DEFAULT 0 NOT NULL CHECK (wins >= 0),
        upd_date  TIMESTAMPTZ,
        PRIMARY KEY (team_id, series_id)
    );

    -- Create trigger to update the series_teams.upd_date field when series_teams is updated
    CREATE FUNCTION update_series_teams_upd_date()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.upd_date = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER t_update_series_team
    BEFORE UPDATE ON series_teams
    FOR EACH ROW
    EXECUTE FUNCTION update_series_teams_upd_date();

    -- Enum which holds the game status values: 'S' - Scheduled, 'L' - Live, 'F' - Final, 'P' - Postponed, 'C' - Cancelled
    CREATE TYPE GAME_STATUS AS ENUM ('S', 'L', 'F', 'P', 'C');

    -- Table which holds each game which is part of the pool
    --
    -- COLUMNS
    -- game_id:      (PK) ID of the game
    -- series_id:    (FK) ID of the series which the game is part of
    -- espn_game_id: ID from the ESPN system which references this game in their database
    -- league:       The league that the game is from
    -- sched_date:   Date that the game will take place
    -- sched_time:   Scheduled start time. This can be NULL since leagues often schedule game dates but wait to set a start time
    -- status:       Status of the game
    -- cr_date:      Timestamp of when the record was added
    -- upd_date:     Timestamp of when the record was updated last
    --
    CREATE TABLE games (
        game_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        series_id    INT REFERENCES series (series_id) NOT NULL,
        espn_game_id BIGINT NOT NULL,
        league       LEAGUE NOT NULL DEFAULT 'NHL',
        sched_date   DATE NOT NULL,
        sched_time   TIMESTAMPTZ,
        status       GAME_STATUS NOT NULL,
        cr_date      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
        upd_date     TIMESTAMPTZ,
        UNIQUE (league, espn_game_id) -- ESPN's IDs are league-specific
    );

    -- Create trigger to update the games.upd_date field when games is updated
    CREATE FUNCTION update_games_upd_date()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.upd_date = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER t_update_games
    BEFORE UPDATE ON games
    FOR EACH ROW
    EXECUTE FUNCTION update_games_upd_date();

    -- Table which links a team with a game that they're participating in, and holds information on whether they are the home team
    --
    -- COLUMNS
    -- team_id: (FK) ID of the team which is participating in the game
    -- game_id: (FK) ID of the game which the team is participating in
    -- home:    Boolean whether the team is the home team
    --
    CREATE TABLE game_teams (
        team_id INT REFERENCES teams (team_id) NOT NULL,
        game_id INT REFERENCES games (game_id) NOT NULL,
        home    BOOL NOT NULL,
        PRIMARY KEY (team_id, game_id)
    );

    -- Enum which represents the type of point being recorded: 'G' - Goal, 'A' - Assist, 'W' - Goalie Win, 'SO' - Goalie Shutout
    CREATE TYPE POINT_TYPE AS ENUM ('G', 'A', 'W', 'SO');

    -- Table which holds the point value mapping to each point type
    --
    -- COLUMNS
    -- point_type:       The type of point
    -- point_value:      The number of points which the type of point is worth
    -- upd_date:         Timestamp of when the record was updated
    --
    CREATE TABLE point_mappings (
        point_type       POINT_TYPE PRIMARY KEY,
        point_value      SMALLINT NOT NULL,
        upd_date         TIMESTAMPTZ
    );

    -- Create trigger to update the point_mappings.upd_date field when point_mappings is updated
    CREATE FUNCTION update_point_mappings_upd_date()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.upd_date = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER t_update_point_mappings
    BEFORE UPDATE ON point_mappings
    FOR EACH ROW
    EXECUTE FUNCTION update_point_mappings_upd_date();

    -- Table which holds each point recorded in a game
    --
    -- COLUMNS
    -- point_id:      (PK) ID of the point
    -- game_id:       (FK) ID of the game in which the point was recorded
    -- player_id:     (FK) ID of the player who recorded the point
    -- espn_event_id: ID from the ESPN system which references this event in their database
    -- league:        The league in which the point was scored
    -- point_type:    The type of point being recorded
    -- pool_pts:      The number of pool points that this point earned. This is recorded at the time the point was recorded and is meant to be preserved in case the value of that point type is modified later
    -- cr_date:       Timestamp of when the record was added
    -- upd_date:      Timestamp of when the record was last updated
    --
    CREATE TABLE points (
        point_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        game_id       INT REFERENCES games (game_id) NOT NULL,
        player_id     INT REFERENCES players (player_id) NOT NULL,
        point_type    POINT_TYPE REFERENCES point_mappings (point_type) NOT NULL,
        espn_event_id BIGINT UNIQUE NOT NULL,
        league        LEAGUE NOT NULL DEFAULT 'NHL',
        pool_pts      SMALLINT NOT NULL,
        cr_date       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
        upd_date      TIMESTAMPTZ,
        UNIQUE (league, espn_event_id) -- ESPN's IDs are league-specific
    );

    -- Create trigger to update the points.upd_date field when points is updated
    CREATE FUNCTION update_points_upd_date()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.upd_date = CURRENT_TIMESTAMP;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER t1_update_points
    BEFORE UPDATE ON points
    FOR EACH ROW
    EXECUTE FUNCTION update_points_upd_date();

COMMIT;