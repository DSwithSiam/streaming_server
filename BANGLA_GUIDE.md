# OBS Streaming Server - সম্পূর্ণ গাইড (বাংলা)

## 🎯 এই সার্ভার কি করে?

এটি একটি live streaming server যেখানে আপনি:
- OBS থেকে stream করতে পারবেন
- Web browser এ live stream দেখতে পারবেন
- Multiple streams একসাথে চালাতে পারবেন

## 📋 প্রয়োজনীয় জিনিস

- Ubuntu/Linux Server
- OBS Studio
- Python 3.x
- Nginx (আমরা install করে দিয়েছি)

---

## 🚀 প্রথমবার Setup (শুধু একবার করতে হবে)

### ১. Nginx RTMP Install করুন

```bash
cd /home/backend/siam/streaming_server/streaming_server
sudo bash setup_nginx_rtmp.sh
```

⏰ সময় লাগবে: 5-10 মিনিট

### ২. Database Setup করুন

```bash
python manage.py makemigrations
python manage.py migrate
```

---

## ▶️ Server Start করার নিয়ম

### Option 1: দুটি আলাদা Terminal এ (Recommended)

**Terminal 1 - Nginx Start:**
```bash
sudo /usr/local/nginx/sbin/nginx
```

**Terminal 2 - Django Start:**
```bash
cd /home/backend/siam/streaming_server/streaming_server
python manage.py runserver 0.0.0.0:8000
```

### Option 2: Quick Start Script (একসাথে)
```bash
bash start_server.sh
```

---

## 🎥 OBS Setup করার নিয়ম

### ১. Stream Key তৈরি করুন

Browser এ যান:
```
http://10.10.13.73:8000/
```

অথবা Terminal থেকে:
```bash
curl "http://localhost:8000/create_stream_key/?title=My%20Stream"
```

আপনি পাবেন:
```json
{
  "stream_key": "abc123xyz...",
  "rtmp_url": "rtmp://localhost/live/abc123xyz...",
  "watch_url": "/watch/abc123xyz.../"
}
```

### ২. OBS Configure করুন

#### Step by Step:

1. **OBS Studio খুলুন**

2. **Settings এ যান** (নিচে Settings button অথবা File → Settings)

3. **Stream সিলেক্ট করুন** (বাম পাশে)

4. **এই settings দিন:**
   - **Service:** `Custom`
   - **Server:** `rtmp://10.10.13.73:1935/live`
   - **Stream Key:** আপনার তৈরি করা stream key (যেমন: `3701179a1d1344b09b61dacc64580930`)

5. **Apply → OK করুন**

6. **Start Streaming button এ ক্লিক করুন** (ডান পাশে)

### ৩. OBS Output Settings (Optional - Better Quality এর জন্য)

Settings → Output:
- **Video Bitrate:** 2500-4000 Kbps
- **Encoder:** x264 (অথবা Hardware NVENC যদি GPU থাকে)
- **Audio Bitrate:** 160 kbps
- **Keyframe Interval:** 2

### ৪. OBS Video Settings (Optional)

Settings → Video:
- **Output Resolution:** 1920x1080 অথবা 1280x720
- **FPS:** 30 অথবা 60

---

## 📺 Stream দেখার নিয়ম

### Browser এ দেখুন:

**Home Page (সব streams দেখতে):**
```
http://10.10.13.73:8000/
```

**নির্দিষ্ট stream দেখতে:**
```
http://10.10.13.73:8000/watch/YOUR_STREAM_KEY/
```

উদাহরণ:
```
http://10.10.13.73:8000/watch/3701179a1d1344b09b61dacc64580930/
```

---

## 🛠️ Server কিভাবে কাজ করে

### Architecture:

```
OBS (RTMP Stream)
    ↓
Nginx RTMP Server (Port 1935)
    ↓
HLS Files (/tmp/hls/) → Nginx HTTP (Port 8080)
    ↓
Django Web Server (Port 8000)
    ↓
Browser (Video Player)
```

### Ports:

- **1935:** RTMP - OBS stream receive করে
- **8080:** HTTP - HLS video files serve করে
- **8000:** HTTP - Django web interface

---

## ✅ সবকিছু ঠিক আছে কিনা Check করুন

### 1. Nginx চালু আছে কিনা:
```bash
ps aux | grep nginx
```

দেখবেন: `nginx: master process` এবং কয়েকটা `worker process`

### 2. Port 1935 (RTMP) খোলা আছে কিনা:
```bash
sudo lsof -i :1935
```

দেখবেন: nginx শুনছে (LISTEN)

### 3. HLS files তৈরি হচ্ছে কিনা:
```bash
ls -la /tmp/hls/
```

Stream চালু থাকলে দেখবেন: `.ts` files এবং `.m3u8` playlist

### 4. HLS accessible কিনা:
```bash
curl -I http://10.10.13.73:8080/live/YOUR_STREAM_KEY.m3u8
```

সফল হলে দেখবেন: `HTTP/1.1 200 OK`

### 5. Django চালু আছে কিনা:
```bash
ps aux | grep "manage.py runserver"
```

---

## 🔧 সমস্যা ও সমাধান

### সমস্যা 1: OBS connect হচ্ছে না

**সমাধান:**
```bash
# Nginx চালু কিনা check করুন
sudo /usr/local/nginx/sbin/nginx

# Port 1935 খোলা আছে কিনা
sudo lsof -i :1935

# Firewall allow করুন
sudo ufw allow 1935
```

### সমস্যা 2: Browser এ video দেখা যাচ্ছে না

**সমাধান:**
```bash
# HLS files আছে কিনা check করুন
ls -la /tmp/hls/

# Nginx reload করুন
sudo /usr/local/nginx/sbin/nginx -s reload

# Browser এ F12 চেপে Console এ error দেখুন
```

### সমস্যা 3: "Port already in use" error

**সমাধান:**
```bash
# কোন process port 8000 ব্যবহার করছে দেখুন
lsof -i :8000

# পুরনো Django process kill করুন
pkill -f "manage.py runserver"

# আবার start করুন
python manage.py runserver 0.0.0.0:8000
```

### সমস্যা 4: Stream lag করছে

**সমাধান:**
- OBS এ bitrate কমান (2500 kbps)
- Output resolution কমান (720p)
- FPS কমান (30)
- Encoder preset: `veryfast` ব্যবহার করুন

---

## ⏹️ Server Stop করার নিয়ম

### Nginx Stop:
```bash
sudo /usr/local/nginx/sbin/nginx -s stop
```

### Django Stop:
Django terminal এ: `Ctrl + C`

### অথবা Quick Stop:
```bash
bash stop_server.sh
```

---

## 📊 API Endpoints

### 1. Stream Key তৈরি করা:
```bash
GET http://10.10.13.73:8000/create_stream_key/?title=My%20Stream
```

Response:
```json
{
  "stream_key": "abc123...",
  "title": "My Stream",
  "rtmp_url": "rtmp://localhost/live/abc123...",
  "watch_url": "/watch/abc123.../"
}
```

### 2. সব Streams দেখা:
```bash
GET http://10.10.13.73:8000/list_streams/
```

Response:
```json
{
  "streams": [
    {
      "stream_key": "abc123...",
      "title": "My Stream",
      "is_live": true,
      "watch_url": "/watch/abc123.../"
    }
  ]
}
```

### 3. নির্দিষ্ট Stream দেখা:
```bash
GET http://10.10.13.73:8000/watch/STREAM_KEY/
```

---

## 🎬 একটি সম্পূর্ণ উদাহরণ

### Scenario: আপনি একটি live gaming stream করতে চান

#### Step 1: Server Start করুন
```bash
# Terminal 1
sudo /usr/local/nginx/sbin/nginx

# Terminal 2
cd /home/backend/siam/streaming_server/streaming_server
python manage.py runserver 0.0.0.0:8000
```

#### Step 2: Stream Key নিন
Browser এ যান: `http://10.10.13.73:8000/`
- "Create New Stream" এ title দিন: "Gaming Live"
- "Create Stream Key" button এ click করুন
- RTMP URL এবং Stream Key copy করুন

#### Step 3: OBS Setup
```
Settings → Stream:
  Service: Custom
  Server: rtmp://10.10.13.73:1935/live
  Stream Key: (আপনার key paste করুন)
```

#### Step 4: Stream Start
- OBS এ "Start Streaming" click করুন
- Browser এ watch URL খুলুন
- Live stream দেখুন! 🎉

---

## 📱 Mobile থেকে দেখা

Mobile browser এ same URL খুলুন:
```
http://10.10.13.73:8000/watch/YOUR_STREAM_KEY/
```

**Note:** আপনার phone এবং server same network এ থাকতে হবে।

---

## 🌐 Internet এ Stream করা (Advanced)

### 1. Server IP Public করুন (Port Forwarding)
Router settings এ:
- Port 1935 → Server IP
- Port 8000 → Server IP

### 2. Domain Name use করুন (Optional)
- Domain কিনুন
- DNS settings এ A record add করুন
- Server IP point করুন

### 3. SSL/HTTPS Setup করুন (Security)
```bash
# Let's Encrypt SSL
sudo apt install certbot
sudo certbot certonly --standalone -d yourdomain.com
```

---

## 💡 Tips & Tricks

### 1. Low Latency এর জন্য:
nginx.conf এ:
```nginx
hls_fragment 1;        # 3 থেকে 1 করুন
hls_playlist_length 3; # 60 থেকে 3 করুন
```

### 2. Recording Enable করতে:
nginx.conf এ:
```nginx
record all;
record_path /var/recordings;
record_suffix _%Y%m%d_%H%M%S.flv;
```

### 3. Multiple Quality (Adaptive Bitrate):
আলাদা streams তৈরি করুন:
- 1080p @ 4000 kbps
- 720p @ 2500 kbps  
- 480p @ 1000 kbps

---

## 📞 সাহায্য প্রয়োজন?

### Logs দেখুন:

**Nginx Error Log:**
```bash
sudo tail -f /usr/local/nginx/logs/error.log
```

**Django Console:**
Terminal এ সরাসরি error দেখাবে

**Browser Console:**
F12 চেপে Console tab এ error দেখুন

---

## 🎓 শেখার Resources

- [OBS Settings Guide](https://obsproject.com/wiki/)
- [RTMP Protocol](https://en.wikipedia.org/wiki/Real-Time_Messaging_Protocol)
- [HLS Streaming](https://developer.apple.com/streaming/)
- [Django Documentation](https://docs.djangoproject.com/)

---

## ✨ Features

- ✅ Real-time RTMP streaming
- ✅ HLS playback (সব browser এ কাজ করে)
- ✅ Multiple streams support
- ✅ Stream management dashboard
- ✅ Low latency mode
- ✅ Auto stream status tracking
- ✅ Mobile friendly player

---

## 🔮 Future Improvements

- [ ] User authentication
- [ ] Stream recording
- [ ] Multiple quality options
- [ ] Chat integration
- [ ] Viewer count
- [ ] Stream analytics
- [ ] Thumbnail generation

---

---

# 📖 দ্রুত রেফারেন্স (Quick Reference)

## ✨ সবচেয়ে গুরুত্বপূর্ণ কমান্ডস

```bash
# Server Start করুন
sudo /usr/local/nginx/sbin/nginx
python manage.py runserver 0.0.0.0:8000

# Server Stop করুন
sudo /usr/local/nginx/sbin/nginx -s stop
# Django: Ctrl+C

# Stream Key তৈরি করুন
curl "http://localhost:8000/create_stream_key/?title=Test"

# সব streams দেখুন
curl http://localhost:8000/list_streams/

# Nginx reload করুন
sudo /usr/local/nginx/sbin/nginx -s reload

# Logs দেখুন
sudo tail -f /usr/local/nginx/logs/error.log
```

---

# 🎬 OBS Settings - কপি করার জন্য

```
Service:    Custom
Server:     rtmp://10.10.13.73:1935/live
Stream Key: [আপনার stream key]
```

---

# 🌐 Important URLs

| কাজ | URL |
|-----|-----|
| Home Page | http://10.10.13.73:8000/ |
| Watch Stream | http://10.10.13.73:8000/watch/STREAM_KEY/ |
| Create Key API | http://10.10.13.73:8000/create_stream_key/ |
| List Streams API | http://10.10.13.73:8000/list_streams/ |

---

# 🔧 Server Directory Structure

```
streaming_server/
├── manage.py                 # Django main
├── db.sqlite3               # Database
├── nginx/
│   └── nginx.conf           # Nginx configuration
├── stream/
│   ├── models.py            # Database models
│   ├── views.py             # API logic
│   ├── urls.py              # URL routing
│   └── migrations/
├── streaming_server/
│   ├── settings.py          # Django settings
│   ├── urls.py              # Main URLs
│   └── wsgi.py
├── templates/
│   └── stream/
│       ├── index.html       # Home page
│       └── watch.html       # Video player
├── setup_nginx_rtmp.sh      # Installation script
├── start_server.sh          # Start script
├── stop_server.sh           # Stop script
├── README.md                # English guide
└── BANGLA_GUIDE.md          # এই ফাইল
```

---

# 🎯 সবচেয়ে সাধারণ সমস্যাগুলি

## ❌ সমস্যা 1: "Connection refused"

**কারণ:** Nginx চালু নেই

**সমাধান:**
```bash
sudo /usr/local/nginx/sbin/nginx
ps aux | grep nginx  # Check করুন
```

---

## ❌ সমস্যা 2: OBS connect হচ্ছে না

**কারণ:** Port 1935 firewall দ্বারা blocked

**সমাধান:**
```bash
sudo ufw allow 1935
sudo ufw allow 8000
sudo ufw allow 8080
```

---

## ❌ সমস্যা 3: Video player blank দেখাচ্ছে

**কারণ:** HLS files serve হচ্ছে না

**সমাধান:**
```bash
# Nginx reload করুন
sudo /usr/local/nginx/sbin/nginx -s reload

# HLS path check করুন
ls -la /tmp/hls/

# Browser cache clear করুন (Ctrl+Shift+Delete)
```

---

## ❌ সমস্যা 4: "Port 8000 already in use"

**কারণ:** Django অন্য terminal এ চলছে

**সমাধান:**
```bash
pkill -f "manage.py runserver"
# অথবা অন্য port use করুন:
python manage.py runserver 0.0.0.0:8001
```

---

# 📊 Performance টিপস

### Low Latency চাইলে:

nginx.conf এ এডিট করুন:
```nginx
hls_fragment 1;           # কম fragment = কম lag
hls_playlist_length 3;    # ছোট playlist
```

তারপর reload:
```bash
sudo /usr/local/nginx/sbin/nginx -s reload
```

### Quality ভালো চাইলে:

OBS Settings:
- Bitrate: 4000-6000 kbps
- Resolution: 1920x1080
- FPS: 60
- Encoder: NVENC (যদি GPU থাকে)

### Network কম থাকলে:

OBS Settings:
- Bitrate: 1000-1500 kbps
- Resolution: 720p
- FPS: 30
- Encoder: x264 (বেশি efficient)

---

# 🔐 নিরাপত্তা ব্যবস্থা

### 1. Firewall সঠিক করুন:
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 1935  # RTMP
sudo ufw allow 8000  # Django
sudo ufw allow 8080  # HLS
sudo ufw enable
```

### 2. Stream Key সুরক্ষিত রাখুন:
- Public URL এ share করবেন না
- private links use করুন
- Strong keys generate করুন

### 3. Production এ SSL/HTTPS use করুন:
```bash
sudo apt install certbot
sudo certbot certonly --standalone -d yourdomain.com
```

---

# 🎓 ডেভেলপমেন্ট টিপস

### 1. Debug Mode চালু করুন:

`streaming_server/settings.py` এ:
```python
DEBUG = True
```

### 2. Database Query দেখুন:

Django shell এ:
```bash
python manage.py shell
```

### 3. Custom Admin Panel:

```bash
python manage.py createsuperuser
# তারপর http://10.10.13.73:8000/admin/
```

---

# 📞 কাস্টমাইজেশন গাইড

### নতুন Stream নাম যোগ করতে:

1. home page এ title add করুন
2. `/create_stream_key/?title=MyTitle` use করুন

### Video player কাস্টমাইজ করতে:

`templates/stream/watch.html` এ edit করুন:
```html
<!-- Color change করুন -->
background: #1a1a1a;  /* নতুন color code */

<!-- Button স্টাইল change করুন -->
background: #667eea;  /* নতুন color */
```

### API Response customize করতে:

`stream/views.py` এ edit করুন:
```python
def list_streams(request):
    # আপনার custom logic এখানে
    return JsonResponse({...})
```

---

# 🚀 Advanced Features

### 1. স্বয়ংক্রিয় Recording:

nginx.conf এ add করুন:
```nginx
record all;
record_path /var/recordings;
record_suffix _%Y%m%d_%H%M%S.flv;
```

### 2. Multiple Bitrate (Adaptive):

আলাদা application একটা add করুন:
```nginx
application live_hd {
    # 1080p 4000kbps
}
application live_sd {
    # 720p 2000kbps
}
```

### 3. Stream Authentication:

OBS-এর জন্য secret key add করুন:
```python
import hashlib
secret = hashlib.sha256(stream_key.encode()).hexdigest()
```

---

# 📱 মোবাইল অপটিমাইজেশন

### Video player responsive করুন:

`watch.html` এ এডিট করুন:
```css
video {
    width: 100%;
    height: 100vh;
    object-fit: contain;
}
```

### টাচ controls add করুন:
```javascript
document.body.addEventListener('click', () => {
    if (video.paused) video.play();
    else video.pause();
});
```

---

# 📈 Monitoring & Statistics

### Real-time stats দেখুন:

```bash
http://localhost:8080/stat
```

### Stream duration track করুন:

`views.py` এ add করুন:
```python
from django.utils import timezone

stream.started_at = timezone.now()
stream.save()
```

---

# 🎨 UI/UX কাস্টমাইজেশন

### Theme change করতে:

`index.html` এ colors এডিট করুন:
```css
/* Primary color */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Button color */
background: #667eea;

/* Live badge */
background: #ff4444;
```

### Font change করতে:

```html
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">

<style>
  font-family: 'Poppins', sans-serif;
</style>
```

---

# 🔍 Debugging Checklist

Stream কাজ করছে না? এই order এ check করুন:

- [ ] Nginx চালু আছে?
  ```bash
  ps aux | grep nginx
  ```

- [ ] Port 1935 লিসেন করছে?
  ```bash
  sudo lsof -i :1935
  ```

- [ ] HLS files তৈরি হচ্ছে?
  ```bash
  ls -la /tmp/hls/
  ```

- [ ] Django চালু আছে?
  ```bash
  curl http://localhost:8000/list_streams/
  ```

- [ ] Firewall allow করেছেন?
  ```bash
  sudo ufw status
  ```

- [ ] nginx.conf syntax ঠিক?
  ```bash
  sudo /usr/local/nginx/sbin/nginx -t
  ```

---

# 💾 ব্যাকআপ নিন

### সমস্ত configuration backup করুন:

```bash
# Database backup
cp db.sqlite3 db.sqlite3.backup

# Nginx config backup
sudo cp /usr/local/nginx/conf/nginx.conf nginx.conf.backup

# Streams backup
tar -czf streams.tar.gz /tmp/hls/
```

---

# 🔄 আপডেট করার নিয়ম

### Django update করুন:

```bash
pip install --upgrade django
python manage.py migrate
```

### Nginx update করুন:

নতুন version compile করুন:
```bash
cd /tmp
wget http://nginx.org/download/nginx-[VERSION].tar.gz
# আবার compile এবং install করুন
```

---

# 📝 Logs সংরক্ষণ করুন

### সব logs একটি ফাইলে সংরক্ষণ করুন:

```bash
# Nginx errors
sudo cp /usr/local/nginx/logs/error.log nginx_errors_$(date +%Y%m%d).log

# Django logs
python manage.py runserver > django_$(date +%Y%m%d).log 2>&1
```

---

# 🎯 Next Steps

1. ✅ Server setup সম্পন্ন
2. ✅ OBS configure সম্পন্ন
3. ⏭️ **এখন আপনি:**
   - Custom domain setup করুন
   - SSL certificate যোগ করুন
   - User authentication যোগ করুন
   - Stream recording enable করুন
   - Analytics যোগ করুন

---

# 📚 শেখার Resource

| বিষয় | লিঙ্ক |
|------|------|
| OBS Documentation | https://obsproject.com/wiki/ |
| Nginx Documentation | https://nginx.org/en/docs/ |
| Django Documentation | https://docs.djangoproject.com/ |
| RTMP Protocol | https://en.wikipedia.org/wiki/Real-Time_Messaging_Protocol |
| HLS Streaming | https://developer.apple.com/streaming/ |

---

# ❓ FAQ (সবচেয়ে বেশি জিজ্ঞাসিত প্রশ্ন)

### Q1: একসাথে কয়টা stream করতে পারব?
**A:** Unlimited, server bandwidth এর উপর নির্ভর করে।

### Q2: Stream কত সময় চলতে পারে?
**A:** Unlimited, যতক্ষণ server চলে।

### Q3: কি server bandwidth সাশ্রয়ী?
**A:** Bitrate কমান অথবা viewers কম রাখুন।

### Q4: Mobile এ stream করতে পারব?
**A:** না, RTMP প্রোটোকল শুধু OBS/Encoder থেকেই কাজ করে।

### Q5: Stream recording করতে পারব?
**A:** হ্যাঁ, nginx.conf এ `record all;` যোগ করুন।

### Q6: Multi-bitrate streaming সম্ভব?
**A:** হ্যাঁ, আলাদা applications configure করুন।

### Q7: Stream password protect করতে পারব?
**A:** হ্যাঁ, custom authentication যোগ করুন।

### Q8: Public internet এ stream করতে পারব?
**A:** হ্যাঁ, port forwarding এবং domain use করুন।

---

# 🎉 সফল Streaming এর জন্য শুভকামনা!

**আপনার streaming server এখন সম্পূর্ণভাবে প্রস্তুত!**

যেকোনো সমস্যা হলে এই guide দেখুন।

Happy Streaming! 🚀📹

---

Created by: OBS Streaming Server Setup
Date: December 25, 2025
Last Updated: Today
