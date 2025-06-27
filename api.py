from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from pathlib import Path
import yt_dlp
import uuid
import os
import json
import time
import asyncio
import threading
from typing import Optional, Dict, Any
import logging

# --- Ayarlar ---
API_KEY = os.getenv("API_KEY", "45541d717524a99df5f994bb9f6cbce825269852be079594b8e35f7752d6f1bd")
DOWNLOAD_DIR = Path("downloads")
DOWNLOAD_DIR.mkdir(exist_ok=True)

app = FastAPI(title="🎬 Linkcim Video Download API", version="2.0.0")
security = HTTPBearer()

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global job storage
jobs: Dict[str, Dict[str, Any]] = {}

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Modeller ---
class DownloadRequest(BaseModel):
    url: str
    format: str = "mp4"
    quality: str = "best"
    platform: Optional[str] = None

class DownloadResponse(BaseModel):
    job_id: str
    status: str
    message: str

# --- Yardımcı Fonksiyonlar ---
def check_api_key(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if credentials.credentials != API_KEY:
        raise HTTPException(status_code=401, detail="🔐 API anahtarı hatalı!")

def get_platform_from_url(url: str) -> str:
    """URL'den platform tespit et"""
    url_lower = url.lower()
    if 'youtube.com' in url_lower or 'youtu.be' in url_lower:
        return 'youtube'
    elif 'instagram.com' in url_lower:
        return 'instagram'
    elif 'tiktok.com' in url_lower:
        return 'tiktok'
    elif 'twitter.com' in url_lower or 'x.com' in url_lower:
        return 'twitter'
    elif 'facebook.com' in url_lower:
        return 'facebook'
    else:
        return 'unknown'

def get_ydl_options(job_id: str, format_type: str, quality: str) -> dict:
    """Platform ve kaliteye göre yt-dlp seçenekleri"""
    base_opts = {
        'outtmpl': str(DOWNLOAD_DIR / f"{job_id}.%(ext)s"),
        'writethumbnail': True,
        'writeinfojson': True,
        'extractaudio': False,
        'ignoreerrors': False,
        'no_warnings': False,
    }
    
    # Format seçenekleri - daha esnek ve uyumlu
    if format_type == "mp4":
        # MP4 formatı için esnek seçenekler
        if quality == "high":
            base_opts['format'] = 'best[height<=1080]/best[height<=720]/best/mp4'
        elif quality == "medium":
            base_opts['format'] = 'best[height<=720]/best[height<=480]/best/mp4'
        elif quality == "low":
            base_opts['format'] = 'best[height<=480]/best[height<=360]/best/mp4'
        else:
            base_opts['format'] = 'best[ext=mp4]/best'
    elif format_type == "mp3":
        base_opts.update({
            'format': 'bestaudio[ext=m4a]/bestaudio/best',
            'extractaudio': True,
            'audioformat': 'mp3',
            'audioquality': '192K',
        })
    else:
        # Genel format - en uyumlu seçenekler
        if quality == "high":
            base_opts['format'] = 'best[height<=1080]/best'
        elif quality == "medium":
            base_opts['format'] = 'best[height<=720]/best'
        elif quality == "low":
            base_opts['format'] = 'best[height<=480]/best'
        else:
            base_opts['format'] = 'best/worst'
    
    return base_opts

async def download_worker(job_id: str, url: str, format_type: str, quality: str):
    """Async video indirme worker'ı"""
    try:
        jobs[job_id] = {
            "status": "starting",
            "progress": 0,
            "url": url,
            "platform": get_platform_from_url(url),
            "format": format_type,
            "quality": quality,
            "created_at": time.time(),
            "file_path": None,
            "file_size": 0,
            "duration": None,
            "title": None,
            "thumbnail": None,
            "error": None
        }
        
        logger.info(f"🚀 İndirme başlatılıyor: {job_id} - {url}")
        
        def progress_hook(d):
            if d['status'] == 'downloading':
                try:
                    percent_str = d.get('_percent_str', '0%').replace('%', '')
                    percent = float(percent_str) if percent_str.replace('.', '').isdigit() else 0
                    jobs[job_id].update({
                        "status": "downloading",
                        "progress": percent,
                        "speed": d.get('_speed_str', 'N/A'),
                        "eta": d.get('_eta_str', 'N/A'),
                        "downloaded": d.get('_downloaded_bytes_str', 'N/A'),
                        "total": d.get('_total_bytes_str', 'N/A')
                    })
                except Exception as e:
                    logger.error(f"Progress güncelleme hatası: {e}")
            elif d['status'] == 'finished':
                jobs[job_id].update({
                    "status": "processing",
                    "progress": 100,
                    "message": "İşleniyor..."
                })
        
        # yt-dlp seçenekleri
        ydl_opts = get_ydl_options(job_id, format_type, quality)
        ydl_opts['progress_hooks'] = [progress_hook]
        
        # İndirme işlemi
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            # Video bilgilerini al
            try:
                info = ydl.extract_info(url, download=False)
                jobs[job_id].update({
                    "title": info.get('title', 'Bilinmiyor'),
                    "duration": info.get('duration', 0),
                    "uploader": info.get('uploader', 'Bilinmiyor'),
                    "view_count": info.get('view_count', 0)
                })
            except Exception as e:
                logger.warning(f"Video bilgisi alınamadı: {e}")
            
            # Video indir
            jobs[job_id]["status"] = "downloading"
            ydl.download([url])
        
        # İndirilen dosyayı bul
        downloaded_files = list(DOWNLOAD_DIR.glob(f"{job_id}.*"))
        video_file = None
        
        for file in downloaded_files:
            if file.suffix.lower() in ['.mp4', '.webm', '.mkv', '.avi', '.mov', '.mp3', '.m4a']:
                video_file = file
                break
        
        if video_file and video_file.exists():
            file_size = video_file.stat().st_size
            jobs[job_id].update({
                "status": "completed",
                "progress": 100,
                "file_path": str(video_file),
                "file_size": file_size,
                "completed_at": time.time(),
                "message": "✅ İndirme tamamlandı!"
            })
            
            # Thumbnail dosyasını bul
            thumbnail_files = list(DOWNLOAD_DIR.glob(f"{job_id}.*"))
            for thumb in thumbnail_files:
                if thumb.suffix.lower() in ['.jpg', '.jpeg', '.png', '.webp']:
                    jobs[job_id]["thumbnail"] = str(thumb)
                    break
                    
            logger.info(f"✅ İndirme tamamlandı: {job_id} - {video_file.name}")
        else:
            raise Exception("İndirilen dosya bulunamadı")
            
    except Exception as e:
        error_msg = str(e)
        logger.error(f"❌ İndirme hatası: {job_id} - {error_msg}")
        jobs[job_id].update({
            "status": "failed",
            "error": error_msg,
            "failed_at": time.time()
        })

# --- API Rotaları ---
@app.get("/")
def root():
    return {
        "name": "🎬 Linkcim Video Download API",
        "version": "2.0.0",
        "status": "running",
        "supported_platforms": [
            "YouTube", "Instagram", "TikTok", "Twitter/X", 
            "Facebook", "Vimeo", "Dailymotion", "Reddit"
        ]
    }

@app.get("/health")
def health():
    active_jobs = len([j for j in jobs.values() if j["status"] in ["downloading", "processing"]])
    completed_jobs = len([j for j in jobs.values() if j["status"] == "completed"])
    failed_jobs = len([j for j in jobs.values() if j["status"] == "failed"])
    
    return {
        "status": "healthy",
        "total_jobs": len(jobs),
        "active_jobs": active_jobs,
        "completed_jobs": completed_jobs,
        "failed_jobs": failed_jobs,
        "uptime": time.time()
    }

@app.post("/download", dependencies=[Depends(check_api_key)])
async def start_download(request: DownloadRequest, background_tasks: BackgroundTasks):
    """🚀 Video indirme işlemini başlat"""
    try:
        job_id = str(uuid.uuid4())
        platform = request.platform or get_platform_from_url(request.url)
        
        logger.info(f"📥 Yeni indirme isteği: {platform} - {request.url}")
        
        # Background task olarak indirme işlemini başlat
        background_tasks.add_task(
            download_worker, 
            job_id, 
            request.url, 
            request.format, 
            request.quality
        )
        
        return DownloadResponse(
            job_id=job_id,
            status="queued",
            message=f"🎬 {platform.title()} videosu indirme kuyruğuna eklendi"
        )
        
    except Exception as e:
        logger.error(f"❌ İndirme başlatma hatası: {e}")
        raise HTTPException(status_code=400, detail=f"İndirme başlatılamadı: {str(e)}")

@app.get("/status/{job_id}", dependencies=[Depends(check_api_key)])
def get_download_status(job_id: str):
    """📊 İndirme durumunu kontrol et"""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="❌ İş bulunamadı")
    
    job = jobs[job_id].copy()
    
    # Hassas bilgileri temizle
    if "error" in job and job["error"]:
        job["error"] = str(job["error"])[:200]  # Hata mesajını kısalt
    
    return job

@app.get("/download/{job_id}", dependencies=[Depends(check_api_key)])
def download_file(job_id: str):
    """📥 Tamamlanan dosyayı indir"""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="❌ İş bulunamadı")
    
    job = jobs[job_id]
    
    if job.get("status") != "completed":
        raise HTTPException(
            status_code=400, 
            detail=f"❌ Dosya henüz hazır değil. Durum: {job.get('status', 'unknown')}"
        )
    
    file_path = job.get("file_path")
    if not file_path or not Path(file_path).exists():
        raise HTTPException(status_code=404, detail="❌ Dosya bulunamadı")
    
    filename = job.get("title", "video")
    # Dosya adını temizle
    filename = "".join(c for c in filename if c.isalnum() or c in (' ', '-', '_')).rstrip()
    filename = f"{filename}.{Path(file_path).suffix[1:]}"
    
    return FileResponse(
        file_path, 
        filename=filename,
        media_type='application/octet-stream'
    )

@app.get("/jobs", dependencies=[Depends(check_api_key)])
def list_all_jobs():
    """📋 Tüm işleri listele"""
    return {
        "total": len(jobs),
        "jobs": [
            {
                "job_id": job_id,
                "status": job["status"],
                "platform": job.get("platform", "unknown"),
                "title": job.get("title", "Bilinmiyor"),
                "progress": job.get("progress", 0),
                "created_at": job.get("created_at"),
                "completed_at": job.get("completed_at"),
                "file_size": job.get("file_size", 0)
            }
            for job_id, job in jobs.items()
        ]
    }

@app.delete("/job/{job_id}", dependencies=[Depends(check_api_key)])
def delete_job(job_id: str):
    """🗑️ İşi ve dosyasını sil"""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="❌ İş bulunamadı")
    
    job = jobs[job_id]
    
    # Dosyaları sil
    if job.get("file_path"):
        try:
            Path(job["file_path"]).unlink(missing_ok=True)
        except Exception as e:
            logger.warning(f"Dosya silinirken hata: {e}")
    
    # Thumbnail'i sil
    if job.get("thumbnail"):
        try:
            Path(job["thumbnail"]).unlink(missing_ok=True)
        except Exception as e:
            logger.warning(f"Thumbnail silinirken hata: {e}")
    
    # İşi sil
    del jobs[job_id]
    
    return {"message": "✅ İş ve dosyalar silindi"}

@app.get("/platforms")
def get_supported_platforms():
    """🌐 Desteklenen platformları listele"""
    return {
        "platforms": {
            "youtube": {
                "name": "YouTube",
                "formats": ["mp4", "mp3"],
                "qualities": ["high", "medium", "low"],
                "features": ["thumbnails", "metadata", "playlists"]
            },
            "instagram": {
                "name": "Instagram",
                "formats": ["mp4"],
                "qualities": ["high", "medium"],
                "features": ["stories", "reels", "posts"]
            },
            "tiktok": {
                "name": "TikTok",
                "formats": ["mp4"],
                "qualities": ["high", "medium"],
                "features": ["no-watermark", "metadata"]
            },
            "twitter": {
                "name": "Twitter/X",
                "formats": ["mp4"],
                "qualities": ["high", "medium"],
                "features": ["multiple-videos"]
            },
            "facebook": {
                "name": "Facebook",
                "formats": ["mp4"],
                "qualities": ["high", "medium"],
                "features": ["posts", "stories"]
            }
        }
    }

@app.get("/api/thumbnail")
async def get_video_thumbnail(url: str):
    """🖼️ Video thumbnail'ını al"""
    try:
        logger.info(f"🖼️ Thumbnail isteniyor: {url}")
        
        # Platform tespit et
        platform = get_platform_from_url(url)
        
        # yt-dlp ile video bilgilerini al (indirmeden)
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'extract_flat': False,
            'writethumbnail': False,
            'writeinfojson': False,
        }
        
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            try:
                info = ydl.extract_info(url, download=False)
                
                # Thumbnail URL'sini al
                thumbnail_url = None
                
                # En iyi kaliteli thumbnail'ı bul
                if 'thumbnails' in info and info['thumbnails']:
                    # En yüksek kaliteli thumbnail'ı seç
                    thumbnails = info['thumbnails']
                    # Width ve height'a göre sırala
                    thumbnails_sorted = sorted(thumbnails, 
                                             key=lambda x: (x.get('width', 0) * x.get('height', 0)), 
                                             reverse=True)
                    
                    if thumbnails_sorted:
                        thumbnail_url = thumbnails_sorted[0]['url']
                elif 'thumbnail' in info:
                    thumbnail_url = info['thumbnail']
                
                if thumbnail_url:
                    logger.info(f"✅ Thumbnail bulundu: {thumbnail_url}")
                    return JSONResponse({
                        "success": True,
                        "thumbnail_url": thumbnail_url,
                        "platform": platform,
                        "title": info.get('title', 'Bilinmiyor'),
                        "duration": info.get('duration', 0),
                        "uploader": info.get('uploader', 'Bilinmiyor')
                    })
                else:
                    logger.warning(f"❌ Thumbnail bulunamadı: {url}")
                    return JSONResponse({
                        "success": False,
                        "error": "Thumbnail bulunamadı",
                        "platform": platform
                    }, status_code=404)
                    
            except Exception as e:
                logger.error(f"❌ Video bilgisi alınamadı: {e}")
                return JSONResponse({
                    "success": False,
                    "error": f"Video bilgisi alınamadı: {str(e)}",
                    "platform": platform
                }, status_code=400)
                
    except Exception as e:
        logger.error(f"❌ Thumbnail endpoint hatası: {e}")
        return JSONResponse({
            "success": False,
            "error": f"Genel hata: {str(e)}"
        }, status_code=500)

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")
