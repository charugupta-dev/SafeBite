import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from summariser import summarize

app = FastAPI(title="AI Website Summarizer API", version="1.0.0")

# Enable CORS for local Flutter / Web / Mobile access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class SummarizeRequest(BaseModel):
    url: str


class SummarizeResponse(BaseModel):
    success: bool
    url: str
    summary: str


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.post("/summarize", response_model=SummarizeResponse)
def summarize_endpoint(req: SummarizeRequest):
    url = req.url.strip()
    if not url:
        raise HTTPException(status_code=400, detail="URL cannot be empty")

    try:
        summary_text = summarize(url)
        if summary_text.startswith("Could not fetch the website"):
            raise HTTPException(status_code=400, detail=summary_text)
        return SummarizeResponse(success=True, url=url, summary=summary_text)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Summarization failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8000)
