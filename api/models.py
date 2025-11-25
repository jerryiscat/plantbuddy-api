from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
from datetime import timedelta

# Custom User Model
class User(AbstractUser):
    email = models.EmailField(unique=True)

# Plant Photo Model - Gallery of photos for each plant
class PlantPhoto(models.Model):
    plant = models.ForeignKey('Plant', on_delete=models.CASCADE, related_name='photos')
    image_url = models.TextField(help_text="URL to the photo")
    uploaded_at = models.DateTimeField(auto_now_add=True)
    is_cover = models.BooleanField(default=False, help_text="Is this the cover photo?")
    
    class Meta:
        ordering = ['-is_cover', '-uploaded_at']
    
    def __str__(self):
        return f"Photo for {self.plant.name}"

# Plant Model
class Plant(models.Model):
    CARE_LEVEL_CHOICES = [
        ('easy', 'Easy'),
        ('moderate', 'Moderate'),
        ('hard', 'Hard'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='plants')
    name = models.CharField(max_length=100)
    species = models.CharField(max_length=100, blank=True, null=True)
    perenual_id = models.IntegerField(null=True, blank=True, help_text="External link to Perenual API")
    care_level = models.CharField(max_length=20, choices=CARE_LEVEL_CHOICES, blank=True, null=True)
    image_url = models.TextField(blank=True, null=True, help_text="Deprecated: Use photos instead. Kept for backward compatibility")
    cover_photo = models.ForeignKey(PlantPhoto, on_delete=models.SET_NULL, null=True, blank=True, related_name='cover_for_plant', help_text="The cover photo for this plant")
    care_tips = models.TextField(blank=True, null=True)
    is_dead = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} ({self.user.username})"
    
    def get_cover_image_url(self):
        """Returns the cover photo URL, or first photo, or legacy image_url"""
        if self.cover_photo:
            return self.cover_photo.image_url
        first_photo = self.photos.first()
        if first_photo:
            return first_photo.image_url
        return self.image_url

# Schedule Model - The rules engine
class Schedule(models.Model):
    TASK_TYPE_CHOICES = [
        ('WATER', 'Water'),
        ('FERTILIZE', 'Fertilize'),
        ('REPOTTING', 'Repotting'),
        ('PRUNE', 'Prune'),
    ]
    
    plant = models.ForeignKey(Plant, on_delete=models.CASCADE, related_name='schedules')
    task_type = models.CharField(max_length=20, choices=TASK_TYPE_CHOICES)
    frequency_days = models.IntegerField(help_text="Number of days between tasks")
    next_due_date = models.DateField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['plant', 'task_type']
        ordering = ['next_due_date']
    
    def __str__(self):
        return f"{self.plant.name} - {self.task_type} (every {self.frequency_days} days)"

# Activity Log Model - The history book
class ActivityLog(models.Model):
    ACTION_TYPE_CHOICES = [
        ('WATER', 'Water'),
        ('FERTILIZE', 'Fertilize'),
        ('REPOTTING', 'Repotting'),
        ('PRUNE', 'Prune'),
        ('SNOOZE', 'Snooze'),
        ('SKIPPED_RAIN', 'Skipped (Rain)'),
        ('PHOTO', 'Photo'),
        ('NOTE', 'Note'),
    ]
    
    plant = models.ForeignKey(Plant, on_delete=models.CASCADE, related_name='activity_logs')
    schedule = models.ForeignKey(Schedule, on_delete=models.SET_NULL, null=True, blank=True, related_name='activity_logs')
    action_type = models.CharField(max_length=20, choices=ACTION_TYPE_CHOICES)
    action_date = models.DateTimeField(default=timezone.now)
    notes = models.TextField(blank=True, null=True)
    photo = models.ForeignKey(PlantPhoto, on_delete=models.SET_NULL, null=True, blank=True, related_name='activity_logs', help_text="Photo associated with this activity (for PHOTO actions)")
    previous_due_date = models.DateField(null=True, blank=True, help_text="Stored for undo functionality")
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-action_date']
    
    def __str__(self):
        return f"{self.plant.name} - {self.action_type} on {self.action_date.date()}"
