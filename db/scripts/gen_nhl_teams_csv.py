# Helper script to generate the CSV file for inserting the NHL playoff team information into the database
# Script leverages the ESPN API: docs https://github.com/pseudo-r/Public-ESPN-API/blob/main/docs/sports/hockey.md
# Command: python ./gen_nhl_teams_csv.py

import requests

from pandas import json_normalize

# ESPN API has no way of filtering playoff teams
playoff_teams = [
    "COL", "LA", "MIN", "DAL", "VGK", "UTAH", "EDM", "ANA",
    "BUF", "BOS", "TB", "MTL", "CAR", "OTT", "PHI", "PIT"
]

# Send GET request to ESPN API to get all of the teams. The API returns a large nested JSON object
api_url = "https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/teams"

ret_data = requests.get(api_url).json()

# Filter out the higher level information to get to the list of teams.
team_objs = ret_data["sports"][0]["leagues"][0]["teams"]

# Use pandas to create a DataFrame which uses the JSON structure as it's column names
teams_df = json_normalize(team_objs, sep=".")

# Filter the DataFrame for playoff teams only
playoff_teams_df = teams_df[teams_df["team.abbreviation"].isin(playoff_teams)].copy()

# team.logos is a list multiple objects, but we only want the primary logo so we apply a lambda function to extract it into a new column
playoff_teams_df["team_logo"] = playoff_teams_df["team.logos"].apply(
    lambda x: x[0]["href"] if (isinstance(x, list) and len(x) > 0) else None
)

# Select only the columns we want, in the expected order, then rename to the expected columns in the "teams" table
playoff_teams_df = playoff_teams_df[["team.id", "team.location", "team.name", "team.abbreviation", "team_logo"]]
playoff_teams_df = playoff_teams_df.rename(columns={
    "team.id": "espn_team_id",
    "team.location": "region",
    "team.name": "nickname",
    "team.abbreviation": "abbr",
    "team_logo": "logo"
})

# Generate the csv file in the expected directory
playoff_teams_df.to_csv("../flyway/data/nhl_teams.csv", index=False)