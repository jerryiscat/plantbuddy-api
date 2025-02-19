from django.contrib.auth.models import AbstractUser
from django.db import models

# Custom User Model
class User(AbstractUser):
    email = models.EmailField(unique=True)

# Plant Model
class Plant(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='plants')
    name = models.CharField(max_length=100)
    species = models.CharField(max_length=100, blank=True, null=True)
    image_url = models.TextField(blank=True, null=True)
    care_tips = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

# Task Model (Linked to Plants)
class Task(models.Model):
    STATUS_CHOICES = [('pending', 'Pending'), ('completed', 'Completed')]
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='tasks')
    plant = models.ForeignKey(Plant, on_delete=models.CASCADE, related_name='tasks')
    title = models.CharField(max_length=255)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    due_date = models.DateField()
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
