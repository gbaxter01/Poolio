# Helper script to generate the CSV file for inserting the drafted players into the database
# Since the pool has already been drafted, I'm using this script to parse the HTML from the other pool site and generate the players table
# Command: python ./gen_pool_players_csv.py

import re
import requests
import pandas as pd

from bs4 import BeautifulSoup
from itertools import chain

output_file = '../flyway/data/pool_players.csv'
print(f'Generating CSV file {output_file}')

# team_table.html is the table of players on each pool team, from the old pool's website
with open('./resources/team_table.html') as fp:
    soup = BeautifulSoup(fp, features='html.parser')

all_rows = soup.find_all('tr')

# The values are the team_id values from the database. This could be a list indexed by the team_id but I felt the dict with the key-value pair was more clear
pool_teams = {
    'Mik': 1,
    'Griffin': 2,
    'Nic': 3,
    'Kieran': 4,
    'Trevor': 5,
    'Adam': 6,
    'Liam': 7,
    'Sam': 8
}

# Using a list of dicts here as this list just needs to be iterated on sequentially
nhl_teams = [
    { 'team_id': 1, 'espn_team_id': 25 },
    { 'team_id': 2, 'espn_team_id': 1 },
    { 'team_id': 3, 'espn_team_id': 2 },
    { 'team_id': 4, 'espn_team_id': 7 },
    { 'team_id': 5, 'espn_team_id': 17 },
    { 'team_id': 6, 'espn_team_id': 9 },
    { 'team_id': 7, 'espn_team_id': 6 },
    { 'team_id': 8, 'espn_team_id': 8 },
    { 'team_id': 9, 'espn_team_id': 30 },
    { 'team_id': 10, 'espn_team_id': 10 },
    { 'team_id': 11, 'espn_team_id': 14 },
    { 'team_id': 12, 'espn_team_id': 15 },
    { 'team_id': 13, 'espn_team_id': 16 },
    { 'team_id': 14, 'espn_team_id': 20 },
    { 'team_id': 15, 'espn_team_id': 129764 },
    { 'team_id': 16, 'espn_team_id': 37 }
]

pool_players = {}

# Build mapping of players to their pool teams. Parse the HTML form team_table.html and link a player to their associated pool_team_id
for tr in all_rows:
    # Use the structure from team_table.html to capture the team name and the player names
    if (tr.get('class', None) and tr.get('class')[0] == 'orange'):
        for td in tr.find_all('td'):
            if td.get('class', None) and td.get('class')[0] == 'name':
                pool_team = re.sub(r' \([0-9]+\)', '', td.a.get_text().strip())
    if (tr.get('class', None)[0] == 'grey'):
        for td in tr.find_all('td'):
            if(td.get('class', None) and td.get('class')[0] == 'padLeft'):
                player = re.sub(r'^([A-Za-z\'-]+), ([A-Za-z\'-]+) \(.+\)', r'\2 \1', td.a.get_text())
                pool_players[player.upper()] = pool_teams[pool_team]

# Create DataFrame to hold all of the pool players
pool_players_df = pd.DataFrame()

# Helper function to check if a player is in a pool team
# This should be updated to use more than just name, but for this year's pool it is sufficient. Next year a live draft will be implemented so this script won't be necessary
# returns: the pool_team_id for the player
def match_pool_team(name):
    if (name.upper() in pool_players):
        value = pool_players.pop(name.upper())
        return value
    return pd.NA

# Search each playoff team for players who are members of a pool team
for team in nhl_teams:
    # Use the team id from ESPN, which is stored in the nhl_teams dict
    espn_team_id = team['espn_team_id']
    api_url = f'https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/teams/{espn_team_id}/roster'

    # The JSON response from ESPN is categorized by positions. Use chain to combine the lists into one list of all players on the team
    ret_data = requests.get(api_url).json()
    players = list(chain.from_iterable(positions['items'] for positions in ret_data['athletes']))

    # Convert the JSON to a DataFrame
    team_players_df = pd.json_normalize(players,  sep='.')

    # Match players to their pool team, then filter out any players who do not have an associated pool team
    team_players_df['pool_team_id'] = team_players_df['fullName'].apply(match_pool_team)
    team_players_df = team_players_df[team_players_df['pool_team_id'].notna()]

    # Set the player's NHL team_id from the poolio system
    team_players_df['team_id'] = team['team_id']

    # Classify the player into 'F' if they are a forward. position.abbreviation already has the correct value for defensemen and goalies
    team_players_df['classification'] = team_players_df['position.abbreviation'].apply(
        lambda x: 'F' if (x in ['C', 'LW', 'RW']) else x
    )

    # Select only the relevant columns for loading the data into the DB
    team_players_df = team_players_df[['pool_team_id', 'team_id', 'id', 'firstName', 'lastName', 'classification']]
    team_players_df = team_players_df.rename(columns={
        'id': 'espn_player_id',
        'firstName': 'first_name',
        'lastName': 'last_name'
    })

    pool_players_df = pd.concat([pool_players_df, team_players_df], ignore_index=True)

# If any pool_players have not been matched, raise the issue and do not generate the CSV file
if (pool_players):
    print('Unmatched pool players:', list(pool_players.keys()))
    print('CSV file will not be generated')
    quit()

# Generate the csv file in the expected directory
pool_players_df.to_csv(output_file, index=False)