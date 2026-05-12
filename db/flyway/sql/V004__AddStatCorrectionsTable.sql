-- Add new table to hold stat corrections which are issued by the nightly audit job.
-- Leagues can issue stat corrections mid-game or up to a week after a game has finished so the system must be able to handle them

BEGIN;
    SET search_path TO poolio, public;

    -- Table which holds log entries which record stat corrections that have been issued
    --
    -- COLUMNS
    -- stat_correction_id: (PK) ID of the stat correction
    -- point_id:           (FK) ID of the point which is affected by the stat correction
    -- description:        description of the stat correction
    --
    CREATE TABLE stat_correction_log (
        stat_correction_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        point_id           INT REFERENCES points(point_id) NOT NULL,
        description        TEXT NOT NULL
    );

    -- Add new "deleted" column to the 'points' table which indicates that a point has been removed by a stat correction
    ALTER TABLE points
    ADD deleted BOOL DEFAULT false NOT NULL;

    -- Update existing entries to ensure they are set
    UPDATE points
    SET deleted = false;

COMMIT;