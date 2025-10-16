from fastapi import FastAPI, Response
from pydantic import BaseModel
import yt_dlp
import uvicorn
from typing import Optional

app = FastAPI()

class Video(BaseModel):
	id: str
	title: str
	uploader: str
	duration: Optional[float]
	views: int
	is_live: bool
	thumbnail: str
	stream_url: str

@app.get("/health")
def health():
	return Response(status_code=200)

def get_highest_res_avatar(thumbnails):
	# Only consider items with "resolution" and roughly 1:1 ratio
	candidates = [t for t in thumbnails if "resolution" in t]
	square_candidates = [t for t in candidates if abs(t["width"]/t["height"] - 1.0) < 0.01]
	if not square_candidates:
		return None
	# Pick largest width * height
	best = max(square_candidates, key=lambda t: t["width"] * t["height"])
	return best["url"]

def get_highest_res_banner(thumbnails):
	# Only consider items with "resolution" (skip avatars and uncropped)
	candidates = [t for t in thumbnails if "resolution" in t]
	if not candidates:
		return None
	# Pick largest width * height
	best = max(candidates, key=lambda t: t["width"] * t["height"])
	return best["url"]


	with yt_dlp.YoutubeDL(ydl_opts) as ydl:
		info = ydl.extract_info(f"https://www.youtube.com/watch?v={id}")

	return {
		"id": info["channel_id"],
		"title": info["eeddspeaks"],
		"desc": info["description"],
		"subscribers": info["channel_follower_count"],
		"videos": info["channel_id"],
		"avatarURL": info["channel_id"],
		"bannerURL": info["channel_id"],
	}

@app.get("/channel/{id}")
def get_channel(id: str):
	ydl_opts = {
		"skip_download": True,
		"extract_flat": True,
	}
	with yt_dlp.YoutubeDL(ydl_opts) as ydl:
		info = ydl.extract_info(f"https://www.youtube.com/channel/{id}/videos")

		print("Channel videos:", info)

		avatar_url = get_highest_res_avatar(info["thumbnails"])
		banner_url = get_highest_res_banner(info["thumbnails"])
  
		videos = []
		for video in info.get("entries", []):
			availability = video.get("availability")
			if availability == "subscriber_only":
				continue

			raw_title = video.get("title")
			if raw_title.isupper() and not raw_title.islower():
				title = raw_title.lower().capitalize()
			else:
				title = raw_title

			thumbnails = video.get("thumbnails")
			thumbnail_url = thumbnails[-1]["url"] if thumbnails else "" # error

			videos.append({
				"id": video.get("id"),
				"title": title,
				"channel_id": info["channel_id"],
				"uploader": info["channel"],
				"duration": video.get("duration"),
				"views": video.get("view_count"),
				"is_live": False,
				"thumbnail": thumbnail_url,
				"stream_url": None
			})

		return {
			"id": info["channel_id"],
			"title": info["channel"],
			"desc": info["description"],
			"subscribers": info["channel_follower_count"],
			"videos": videos,
			"avatar_url": avatar_url,
			"banner_url": banner_url,
		}

@app.get("/video/{id}")
def get_video(id: str):
	ydl_opts = {
		"skip_download": True,
		"format": "best",
	}
#			[ext=mp4][acodec!=none][vcodec!=none]


	with yt_dlp.YoutubeDL(ydl_opts) as ydl:
		info = ydl.extract_info(f"https://www.youtube.com/watch?v={id}")

		print("FORMATS:", info.get("formats"))

	progressive_formats = [
		f for f in info.get("formats")
		if f.get("acodec") != "none"
		and f.get("vcodec") != "none"
		and f.get("ext") == "mp4"   # only MP4 files
		and not f.get("protocol", "").startswith("m3u8")  # skip HLS
	]
	
	best_format = max(
		progressive_formats,
		key=lambda f: f.get("height", 0),
		default=None
	)

	headers = best_format.get("http_headers", {})

	return {
		"stream_url": best_format["url"],
		"headers": headers
	}

# TODO: channel_id vois käyttää sub-napin lisäämiseen
@app.post("/search")
def search(q: str):
	ydl_opts = {
		"extract_flat": True
	}

	with yt_dlp.YoutubeDL(ydl_opts) as ydl:
		info = ydl.extract_info(f"ytsearch10:{q}")

		results = []
		for entry in info.get("entries", []):
			availability = entry.get("availability")
			if availability == "subscriber_only":
				continue

			url = entry.get("url")
			if "/channel/" in url or "/shorts/" in url:
				continue

			live_status = entry.get("live_status")
			is_live = live_status not in (None, "was_live", False)

			raw_title = entry.get("title")
			if raw_title.isupper() and not raw_title.islower():
				title = raw_title.lower().capitalize()
			else:
				title = raw_title

			thumbnails = entry.get("thumbnails")
			thumbnail_url = thumbnails[-1]["url"] if thumbnails else "" # error

			duration = None if is_live else entry.get("duration")

			views = entry.get("concurrent_view_count") if is_live else entry.get("view_count", 0)

			results.append({
				"id": entry.get("id"),
				"title": title,
				"channel_id": entry.get("channel_id"),
				"uploader": entry.get("uploader"),
				"duration": duration,
				"views": views,
				"is_live": is_live,
				"thumbnail": thumbnail_url,
				"stream_url": None
			})

		return results

if __name__ == "__main__":
	uvicorn.run(
	 	app,
		host="127.0.0.1",
		port=8777,
		#reload=True,
		log_level="info",
		workers=1
	)
