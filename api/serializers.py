from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.core.mail import send_mail
from django.conf import settings
from .models import User, Plant, Schedule, ActivityLog, PlantPhoto

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password']
        extra_kwargs = {
            'password': {'write_only': True}
        }
    
    def validate_email(self, value):
        """Check if email is already registered"""
        if self.instance is None:  # Creating new user
            if User.objects.filter(email=value).exists():
                raise serializers.ValidationError("An account with this email already exists.")
        return value
    
    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User.objects.create(**validated_data)
        user.set_password(password)
        user.save()
        return user

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        # Add custom claims
        data['username'] = self.user.username
        data['email'] = self.user.email
        data['user_id'] = self.user.id
        return data

class ScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Schedule
        fields = ['id', 'task_type', 'frequency_days', 'next_due_date', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']

class PlantPhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlantPhoto
        fields = ['id', 'image_url', 'uploaded_at', 'is_cover']
        read_only_fields = ['uploaded_at']

class ActivityLogSerializer(serializers.ModelSerializer):
    photo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = ActivityLog
        fields = ['id', 'action_type', 'action_date', 'notes', 'photo_url', 'created_at']
        read_only_fields = ['created_at']
    
    def get_photo_url(self, obj):
        if obj.photo:
            return obj.photo.image_url
        return None

class PlantSerializer(serializers.ModelSerializer):
    schedules = ScheduleSerializer(many=True, read_only=True)
    photos = PlantPhotoSerializer(many=True, read_only=True)
    cover_photo_id = serializers.PrimaryKeyRelatedField(source='cover_photo', queryset=PlantPhoto.objects.all(), allow_null=True, write_only=True)
    cover_image_url = serializers.SerializerMethodField()
    next_water_date = serializers.SerializerMethodField()
    
    class Meta:
        model = Plant
        fields = [
            'id', 'name', 'species', 'perenual_id', 'care_level', 
            'image_url', 'care_tips', 'is_dead', 'created_at', 
            'updated_at', 'schedules', 'photos', 'cover_photo_id', 
            'cover_image_url', 'next_water_date'
        ]
        read_only_fields = ['created_at', 'updated_at']
    
    def get_cover_image_url(self, obj):
        """Get the cover photo URL"""
        return obj.get_cover_image_url()
    
    def get_next_water_date(self, obj):
        """Get the next water date from schedules"""
        water_schedule = obj.schedules.filter(task_type='WATER', is_active=True).first()
        if water_schedule:
            return water_schedule.next_due_date
        return None

class TaskSerializer(serializers.Serializer):
    """Serializer for task list (combines schedule and plant data)"""
    id = serializers.IntegerField()
    plant_id = serializers.IntegerField()
    plant_name = serializers.CharField()
    task_type = serializers.CharField()
    due_date = serializers.DateField()
    frequency_days = serializers.IntegerField()
    schedule_id = serializers.IntegerField()
