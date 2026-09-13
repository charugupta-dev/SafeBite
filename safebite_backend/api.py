import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

try:
    from agent import analyze_food_safety
except ImportError:
    from safebite_backend.agent import analyze_food_safety

app = FastAPI(title="Safebite API", version="1.0.0")

# Enable CORS for local Flutter / Web / Mobile access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class FoodScanRequest(BaseModel):
    food: str
    target: str


class FoodScanResponse(BaseModel):
    success: bool
    verdict: str
    tools_used: list[str] = []


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.post("/check-food", response_model=FoodScanResponse)
def check_food_endpoint(req: FoodScanRequest):
    food = req.food.strip()
    target = req.target.strip()
    
    if not food or not target:
        raise HTTPException(status_code=400, detail="Food and target cannot be empty")

    try:
        data = analyze_food_safety(food, target, return_metadata=True)
        return FoodScanResponse(
            success=True,
            verdict=data.get("content") or "",
            tools_used=data.get("tools_used") or [],
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Safebite AI failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
