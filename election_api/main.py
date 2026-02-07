# main.py
from fastapi import FastAPI, HTTPException, Query
import requests
from elections_csv_loader import load_elections
from data_loader import load_elections_data, load_measures

app = FastAPI()
#elections = load_elections("elections.csv")
elections, races, candidates = load_elections_data()
measures = load_measures("measures.csv")
app = FastAPI(title="Address-based Election API")

GEOCODE_URL = "https://nominatim.openstreetmap.org/search"

def geocode_address(address: str):
    """Geocode an address to get state, county, city."""
    params = {
        "q": address,
        "format": "json",
        "addressdetails": 1,
        "limit": 1
    }
    response = requests.get(GEOCODE_URL, params=params, headers={"User-Agent": "ElectionAPI/1.0"})
    data = response.json()
    
    if not data:
        return None
    
    addr = data[0].get("address", {})
    return {
        "state": addr.get("state"),
        "county": addr.get("county"),
        "city": addr.get("city") or addr.get("town") or addr.get("village")
    }

def filter_elections(location: dict):
    """Return elections that match the location."""
    state = location.get("state")
    county = location.get("county")
    city = location.get("city")
    
    results = []
    for e in elections:
        if e["level"] == "national":
            results.append(e)
        elif e["level"] == "state" and e["state"] == state:
            results.append(e)
        elif e["level"] == "local" and e["state"] == state and e["county"] == county:
            results.append(e)
    return results

@app.get("/elections")
def get_elections(address: str = Query(..., description="Full address to check elections for")):
    location = geocode_address(address)
    print("User Input",location)
    if not location:
        raise HTTPException(status_code=404, detail="Address could not be geocoded")
    
    upcoming = filter_elections(location)
    
    return {
        "address": address,
        "location": location,
        "elections": upcoming
    }


@app.get("/elections/{election_id}")
@app.get("/elections/{election_id}")
def get_election_detail(election_id: int):
    # 1. Find election
    election = next((e for e in elections if e["id"] == election_id), None)
    if not election:
        raise HTTPException(status_code=404, detail="Election not found")

    # 2. Find races for this election
    election_races = []
    for race in races:
        if race["election_id"] == election_id:
            # 3. Find candidates for this race
            race_candidates = [
                c for c in candidates if c["race_id"] == race["id"]
            ]

            election_races.append({
                "id": race["id"],
                "term": race.get("term"),
                "race_name": race["race_name"],
                "num_candidates": race["num_candidates"],
                "candidates": race_candidates
            })

    # 4. Find measures for this election
    election_measures = [
        {
            "id": m["id"],
            "title": m["title"],
            "description": m["description"],
            "yes_description": m.get("yes_description"),
            "no_description": m.get("no_description")
        }
        for m in measures
        if m["election_id"] == election_id
    ]

    return {
        "election": election,
        "races": election_races,
        "measures": election_measures  # 👈 NEW
    }

