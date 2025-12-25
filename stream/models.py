from django.db import models
import uuid

class Stream(models.Model):
    stream_key = models.CharField(max_length=255, unique=True, default=uuid.uuid4)
    title = models.CharField(max_length=255, default="Untitled Stream")
    is_live = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.title} ({self.stream_key})"
    
    class Meta:
        ordering = ['-created_at']
