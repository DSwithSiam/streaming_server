from django.urls import path
from .views import index, watch_stream, create_stream_key, list_streams, on_publish, on_publish_done


urlpatterns = [
    path('', index, name='index'),
    path('watch/<str:stream_key>/', watch_stream, name='watch_stream'),
    path('create_stream_key/', create_stream_key, name='create_stream_key'),
    path('list_streams/', list_streams, name='list_streams'),
    path('on_publish/', on_publish, name='on_publish'),
    path('on_publish_done/', on_publish_done, name='on_publish_done'),
]
