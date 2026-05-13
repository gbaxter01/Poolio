-- Add all players which have been drafted to a pool team from the pool_teams.csv file

BEGIN;
    SET search_path TO poolio, public;

    -- Insert drafted players from pool_teams.csv
    COPY players(pool_team_id, team_id, espn_player_id, first_name, last_name, classification)
    FROM '/tmp/data/pool_players.csv'
    DELIMITER ','
    CSV HEADER;
COMMIT;