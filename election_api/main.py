# main.py
from fastapi import FastAPI, HTTPException, Query, Depends
import requests
from elections_csv_loader import load_elections
from data_loader import load_elections_data, load_measures
from pydantic import BaseModel, EmailStr
from datetime import date
from sqlalchemy import Column, Integer, String, Date
from sqlalchemy.orm import Session
from database import Base, engine, get_db
from models import User
from passlib.context import CryptContext


app = FastAPI()

class SignInRequest(BaseModel):
    email: str
    password: str



#elections = load_elections("elections.csv")
elections, races, candidates = load_elections_data()
measures = load_measures("measures.csv")
app = FastAPI(title="Address-based Election API")

GEOCODE_URL = "https://nominatim.openstreetmap.org/search"

@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
MAX_BCRYPT_LEN = 72
def hash_password(password: str) -> str:
    truncated = password[:MAX_BCRYPT_LEN]  # truncate if too long
    return pwd_context.hash(truncated)




class UserCreate(BaseModel):
    name: str
    date_of_birth: date
    gender: str
    address: str
    email: EmailStr
    password: str


@app.post("/users")
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # Check duplicate email
    existing = db.query(User).filter(User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    db_user = User(
        name=user.name,
        date_of_birth=user.date_of_birth,
        gender=user.gender,
        address=user.address,
        email=user.email,
        hashed_password=hash_password(user.password),
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return {
        "success": True,
        "message": "User created successfully",
        "user_id": db_user.id
    }

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


def verify_password(plain_password, hashed_password):
    truncated = plain_password[:MAX_BCRYPT_LEN]
    return pwd_context.verify(truncated, hashed_password)


@app.post("/users/signin")
def signin(data: SignInRequest, db: Session = Depends(get_db)):
    # 1. Fetch user by email
    user = db.query(User).filter(User.email == data.email).first()
    
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    # 2. Verify password
    if not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    # 3. Success
    return {"success": True, "address": user.address}


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



@app.get("/users/by_email")
def get_user_by_email(email: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "date_of_birth": user.date_of_birth,
        "gender": user.gender,
        "address": user.address
    }
