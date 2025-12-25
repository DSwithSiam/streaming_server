from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Stream
from django.conf import settings
import uuid
import json

def get_server_host(request):
    """Get server host from settings or request"""
    return getattr(settings, 'SERVER_HOST', request.get_host().split(':')[0])


def index(request):
    """Home page with stream manager"""
    return render(request, "stream/index.html")


def watch_stream(request, stream_key):
    stream = get_object_or_404(Stream, stream_key=stream_key)
    return render(request, "stream/watch.html", {
        "stream_key": stream_key,
        "stream": stream
    })


def create_stream_key(request):
    stream = Stream.objects.create(
        stream_key=uuid.uuid4().hex,
        title=request.GET.get('title', 'Untitled Stream')
    )
    return JsonResponse({
        "stream_key": stream.stream_key,
        "title": stream.title,
        "rtmp_url": f"rtmp://localhost/live/{stream.stream_key}",
        "watch_url": f"/watch/{stream.stream_key}/"
    })


def list_streams(request):
    streams = Stream.objects.all()
    server_host = get_server_host(request)
    rtmp_port = getattr(settings, 'RTMP_PORT', 1935)
    return JsonResponse({
        "streams": [
            {
                "stream_key": s.stream_key,
                "title": s.title,
                "is_live": s.is_live,
                "rtmp_url": f"rtmp://{server_host}:{rtmp_port}/live/{s.stream_key}",
                "watch_url": f"/watch/{s.stream_key}/"
            } for s in streams
        ]
    })


@csrf_exempt
def on_publish(request):
    """Called by nginx-rtmp when stream starts"""
    if request.method == 'POST':
        stream_key = request.POST.get('name', '')
        try:
            stream = Stream.objects.get(stream_key=stream_key)
            stream.is_live = True
            stream.save()
            return HttpResponse(status=200)
        except Stream.DoesNotExist:
            return HttpResponse(status=404)
    return HttpResponse(status=405)


@csrf_exempt
def on_publish_done(request):
    """Called by nginx-rtmp when stream ends"""
    if request.method == 'POST':
        stream_key = request.POST.get('name', '')
        try:
            stream = Stream.objects.get(stream_key=stream_key)
            stream.is_live = False
            stream.save()
            return HttpResponse(status=200)
        except Stream.DoesNotExist:
            return HttpResponse(status=404)
    return HttpResponse(status=405)
