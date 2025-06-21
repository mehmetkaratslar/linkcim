from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
from fastapi.responses import FileResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from pathlib import Path
import yt_dlp, uuid, os

# --- Ayarlar ---
API_KEY = os.getenv("API_KEY", "your-secret-api-key")
DOWNLOAD_DIR = Path("downloads"); DOWNLOAD_DIR.mkdir(exist_ok=True)
app = FastAPI(title="yt-dlp API", version="1.0.0")
security = HTTPBearer()
jobs = {}

# --- Modeller ---
class Req(BaseModel):
    url: str
    format: str = "mp4"

# --- Yardımcılar ---
def check_key(creds: HTTPAuthorizationCredentials = Depends(security)):
    if creds.credentials != API_KEY:
        raise HTTPException(status_code=401, detail="API key hatalı")

async def worker(job_id, url, fmt):
    jobs[job_id] = {"status": "downloading", "progress": 0}
    opts = {
        "format": fmt,
        "outtmpl": str(DOWNLOAD_DIR / f"{job_id}.%(ext)s"),
        "progress_hooks": [lambda d: jobs[job_id].update(progress=float(d.get('_percent_str','0').replace('%','')) if d['status']=='downloading' else {})],
    }
    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            ydl.download([url])
        jobs[job_id]["status"] = "completed"
        jobs[job_id]["file"] = next(DOWNLOAD_DIR.glob(f"{job_id}.*")).as_posix()
    except Exception as e:
        jobs[job_id] = {"status":"failed","error":str(e)}

# --- Rotalar ---
@app.get("/health")
def health(): return {"status":"ok","jobs":len(jobs)}

@app.post("/download", dependencies=[Depends(check_key)])
def start(req: Req, bg: BackgroundTasks):
    job_id = str(uuid.uuid4())
    fmt = "best[ext=mp4]/best" if req.format=="mp4" else "best"
    bg.add_task(worker, job_id, req.url, fmt)
    return {"job_id": job_id, "status": "queued"}

@app.get("/status/{job_id}", dependencies=[Depends(check_key)])
def status(job_id: str):
    if job_id not in jobs: raise HTTPException(404, "Job yok")
    return jobs[job_id]

@app.get("/download/{job_id}", dependencies=[Depends(check_key)])
def fetch(job_id: str):
    job = jobs.get(job_id)
    if not job or job.get("status") != "completed":
        raise HTTPException(400, "Hazır değil")
    return FileResponse(job["file"], filename=os.path.basename(job["file"]))
