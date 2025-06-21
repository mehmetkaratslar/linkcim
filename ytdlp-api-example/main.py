from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
from fastapi.responses import FileResponse, StreamingResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import yt_dlp
import os
import uuid
import json
import asyncio
from typing import Optional, Dict, Any
import logging
from pathlib import Path
import aiofiles

# Logging ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="yt-dlp API", version="1.0.0")
security = HTTPBearer()

# Konfigürasyon
API_KEY = os.getenv("API_KEY", "your-secret-api-key")
DOWNLOAD_DIR = Path("downloads")
DOWNLOAD_DIR.mkdir(exist_ok=True)

# İndirme durumları
download_status: Dict[str, Dict[str, Any]] = {}

class DownloadRequest(BaseModel):
    url: str
    format: str = "mp4"
    quality: str = "best"

class DownloadResponse(BaseModel):
    job_id: str
    status: str
    message: str

def verify_api_key(credentials: HTTPAuthorizationCredentials = Depends(security)):
    logger.info(f"🔑 API Key kontrolü: Gelen={credentials.credentials[:10]}..., Beklenen={API_KEY[:10]}...")
    if credentials.credentials != API_KEY:
        logger.error(f"❌ API Key hatalı! Gelen: {credentials.credentials[:10]}..., Beklenen: {API_KEY[:10]}...")
        raise HTTPException(status_code=401, detail="Invalid API key")
    logger.info("✅ API Key doğru!")
    return credentials.credentials

def progress_hook(d):
    """yt-dlp progress callback"""
    job_id = d.get('info_dict', {}).get('id', 'unknown')
    
    if d['status'] == 'downloading':
        percent = d.get('_percent_str', '0%').replace('%', '')
        try:
            percent_float = float(percent)
            if job_id in download_status:
                download_status[job_id].update({
                    'status': 'downloading',
                    'progress': percent_float,
                    'speed': d.get('_speed_str', ''),
                    'eta': d.get('_eta_str', ''),
                })
        except:
            pass
    elif d['status'] == 'finished':
        if job_id in download_status:
            download_status[job_id].update({
                'status': 'completed',
                'progress': 100,
                'file_path': d['filename']
            })

async def download_video(job_id: str, url: str, format_selector: str):
    """Background video download task"""
    try:
        download_status[job_id] = {
            'status': 'starting',
            'progress': 0,
            'url': url,
            'format': format_selector
        }

        # yt-dlp options
        ydl_opts = {
            'format': format_selector,
            'outtmpl': str(DOWNLOAD_DIR / f'{job_id}.%(ext)s'),
            'progress_hooks': [progress_hook],
            'no_warnings': True,
            'extractaudio': False,
            'audioformat': 'mp3',
            'ignoreerrors': True,  # Subtitle hatalarını yok say
            'writesubtitles': False,  # Subtitle indirmeyi kapat
            'writeautomaticsub': False,  # Otomatik subtitle'ı kapat
        }

        # Platform-specific optimizations
        if 'youtube.com' in url or 'youtu.be' in url:
            ydl_opts.update({
                'format': 'best[height<=720]',  # YouTube için 720p max
                'merge_output_format': 'mp4',
            })
        elif 'instagram.com' in url:
            ydl_opts.update({
                'format': 'best',
            })

        download_status[job_id]['status'] = 'downloading'
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            video_id = info.get('id', job_id)
            title = info.get('title', 'Unknown')
            
            download_status[job_id].update({
                'video_id': video_id,
                'title': title,
                'duration': info.get('duration', 0),
                'uploader': info.get('uploader', ''),
            })
            
            # Actual download
            ydl.download([url])
            
        logger.info(f"Download completed for job {job_id}")
        
    except Exception as e:
        logger.error(f"Download failed for job {job_id}: {str(e)}")
        download_status[job_id] = {
            'status': 'failed',
            'error': str(e),
            'progress': 0
        }

@app.get("/")
async def root():
    return {"message": "yt-dlp API Server", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "downloads": len(download_status)}

@app.post("/download", response_model=DownloadResponse)
async def start_download(
    request: DownloadRequest, 
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """Start a new download job"""
    job_id = str(uuid.uuid4())
    
    # Format selector
    format_map = {
        "mp4": "best[ext=mp4]/best",
        "mp3": "bestaudio[ext=m4a]/bestaudio",
        "best": "best",
        "720p": "best[height<=720]",
        "480p": "best[height<=480]",
    }
    
    format_selector = format_map.get(request.format, "best")
    
    # Start background download
    background_tasks.add_task(download_video, job_id, request.url, format_selector)
    
    return DownloadResponse(
        job_id=job_id,
        status="queued",
        message="Download started"
    )

@app.get("/status/{job_id}")
async def get_download_status(job_id: str, api_key: str = Depends(verify_api_key)):
    """Get download status"""
    if job_id not in download_status:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return download_status[job_id]

@app.get("/download/{job_id}")
async def download_file(job_id: str, api_key: str = Depends(verify_api_key)):
    """Download the completed file"""
    if job_id not in download_status:
        raise HTTPException(status_code=404, detail="Job not found")
    
    job = download_status[job_id]
    
    if job['status'] != 'completed':
        raise HTTPException(status_code=400, detail="Download not completed")
    
    file_path = job.get('file_path')
    if not file_path or not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    
    filename = os.path.basename(file_path)
    return FileResponse(
        file_path,
        media_type='application/octet-stream',
        filename=filename
    )

@app.delete("/download/{job_id}")
async def delete_download(job_id: str, api_key: str = Depends(verify_api_key)):
    """Delete a download and its file"""
    if job_id not in download_status:
        raise HTTPException(status_code=404, detail="Job not found")
    
    job = download_status[job_id]
    file_path = job.get('file_path')
    
    # Delete file if exists
    if file_path and os.path.exists(file_path):
        os.remove(file_path)
    
    # Remove from status
    del download_status[job_id]
    
    return {"message": "Download deleted"}

@app.get("/jobs")
async def list_jobs(api_key: str = Depends(verify_api_key)):
    """List all download jobs"""
    return {
        "total": len(download_status),
        "jobs": download_status
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 