from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from django.db.models import Q
from datetime import timedelta, date
import requests
from .models import User, Plant, Schedule, ActivityLog, PlantPhoto
from .serializers import (
    UserSerializer, PlantSerializer, ScheduleSerializer, 
    ActivityLogSerializer, TaskSerializer, CustomTokenObtainPairSerializer,
    PlantPhotoSerializer
)

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    def get_permissions(self):
        """Allow user registration without authentication"""
        if self.action in ['create']:  
            return [AllowAny()]
        return [IsAuthenticated()]  

    def create(self, request, *args, **kwargs):
        """Override create to handle email duplicate check"""
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            self.perform_create(serializer)
            headers = self.get_success_headers(serializer.data)
            return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get', 'put'], permission_classes=[IsAuthenticated])
    def me(self, request):
        """Allows users to GET their profile or UPDATE their profile"""
        if request.method == 'GET':
            serializer = UserSerializer(request.user)
            return Response(serializer.data)

        elif request.method == 'PUT':
            serializer = UserSerializer(request.user, data=request.data, partial=True)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=400)

class PlantViewSet(viewsets.ModelViewSet):
    serializer_class = PlantSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Filter plants by user and exclude dead plants by default"""
        queryset = Plant.objects.filter(user=self.request.user)
        
        # For graveyard endpoint, we'll override this
        if self.action == 'graveyard':
            return queryset.filter(is_dead=True)
        
        # Default: only show alive plants
        return queryset.filter(is_dead=False)
    
    def list(self, request, *args, **kwargs):
        """GET /api/plants - Returns all alive plants with schedules"""
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def create(self, request, *args, **kwargs):
        """POST /api/plants - Creates a new plant"""
        data = request.data.copy()
        data['user'] = request.user.id
        
        serializer = self.get_serializer(data=data)
        if serializer.is_valid():
            plant = serializer.save()
            
            # Optionally create default water schedule
            if 'frequency_days' in request.data:
                Schedule.objects.create(
                    plant=plant,
                    task_type='WATER',
                    frequency_days=request.data.get('frequency_days', 7),
                    next_due_date=date.today() + timedelta(days=request.data.get('frequency_days', 7))
                )
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def graveyard(self, request):
        """GET /api/plants/graveyard - Returns all dead plants"""
        plants = Plant.objects.filter(user=request.user, is_dead=True)
        serializer = self.get_serializer(plants, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def action(self, request, pk=None):
        """
        POST /api/plants/{id}/action - The Most Important Endpoint
        Input: { "action_type": "WATER", "notes": "Optional notes" }
        """
        plant = self.get_object()
        action_type = request.data.get('action_type')
        notes = request.data.get('notes', '')
        
        if not action_type:
            return Response({'error': 'action_type is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        if action_type not in [choice[0] for choice in ActivityLog.ACTION_TYPE_CHOICES]:
            return Response({'error': f'Invalid action_type: {action_type}'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Find related schedule if this is a scheduled task
        schedule = None
        if action_type in ['WATER', 'FERTILIZE', 'REPOTTING', 'PRUNE']:
            schedule = plant.schedules.filter(task_type=action_type, is_active=True).first()
        
        # Store previous due date for undo
        previous_due_date = schedule.next_due_date if schedule else None
        
        # Handle PHOTO action - create photo and add to gallery
        photo = None
        if action_type == 'PHOTO':
            image_url = request.data.get('image_url')
            if image_url:
                photo = PlantPhoto.objects.create(
                    plant=plant,
                    image_url=image_url
                )
                # If this is the first photo, set it as cover
                if not plant.cover_photo and not plant.photos.exclude(id=photo.id).exists():
                    plant.cover_photo = photo
                    plant.save()
        
        # Create activity log
        activity_log = ActivityLog.objects.create(
            plant=plant,
            schedule=schedule,
            action_type=action_type,
            action_date=timezone.now(),
            notes=notes,
            photo=photo,
            previous_due_date=previous_due_date
        )
        
        # Smart Logic: Update schedule based on action type
        if action_type == 'WATER' and schedule:
            # Rule 1: The Watering Math
            new_due_date = date.today() + timedelta(days=schedule.frequency_days)
            schedule.next_due_date = new_due_date
            schedule.save()
        
        elif action_type == 'FERTILIZE' and schedule:
            new_due_date = date.today() + timedelta(days=schedule.frequency_days)
            schedule.next_due_date = new_due_date
            schedule.save()
        
        elif action_type == 'REPOTTING' and schedule:
            new_due_date = date.today() + timedelta(days=schedule.frequency_days)
            schedule.next_due_date = new_due_date
            schedule.save()
        
        elif action_type == 'PRUNE' and schedule:
            new_due_date = date.today() + timedelta(days=schedule.frequency_days)
            schedule.next_due_date = new_due_date
            schedule.save()
        
        elif action_type == 'SNOOZE' and schedule:
            # Rule 2: The "Snooze" Math - delay by 1 day
            schedule.next_due_date = date.today() + timedelta(days=1)
            schedule.save()
        
        elif action_type == 'SKIPPED_RAIN' and schedule:
            # Treat as completed, reschedule normally
            new_due_date = date.today() + timedelta(days=schedule.frequency_days)
            schedule.next_due_date = new_due_date
            schedule.save()
        
        # PHOTO and NOTE don't affect schedules
        
        return Response({
            'message': f'{action_type} action recorded',
            'activity_log': ActivityLogSerializer(activity_log).data,
            'next_due_date': schedule.next_due_date if schedule else None
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def undo(self, request, pk=None):
        """
        POST /api/plants/{id}/undo - Undo the most recent action
        """
        plant = self.get_object()
        
        # Get the most recent activity log
        last_activity = plant.activity_logs.order_by('-action_date').first()
        
        if not last_activity:
            return Response({'error': 'No activity to undo'}, status=status.HTTP_404_NOT_FOUND)
        
        # Restore previous due date if it was stored
        if last_activity.schedule and last_activity.previous_due_date:
            last_activity.schedule.next_due_date = last_activity.previous_due_date
            last_activity.schedule.save()
        
        # Delete the activity log
        last_activity.delete()
        
        return Response({
            'message': 'Action undone successfully',
            'next_due_date': last_activity.schedule.next_due_date if last_activity.schedule else None
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def mark_dead(self, request, pk=None):
        """
        POST /api/plants/{id}/mark_dead - Rule 3: The "Graveyard" Logic
        """
        plant = self.get_object()
        plant.is_dead = True
        plant.save()
        
        # Deactivate all schedules for dead plant
        plant.schedules.update(is_active=False)
        
        return Response({
            'message': 'Plant marked as dead',
            'plant': PlantSerializer(plant).data
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def schedules(self, request, pk=None):
        """
        POST /api/plants/{id}/schedules/ - Create a new schedule for the plant
        """
        plant = self.get_object()
        task_type = request.data.get('task_type')
        frequency_days = request.data.get('frequency_days')
        
        if not task_type or not frequency_days:
            return Response(
                {'error': 'task_type and frequency_days are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if task_type not in [choice[0] for choice in Schedule.TASK_TYPE_CHOICES]:
            return Response(
                {'error': f'Invalid task_type: {task_type}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if schedule already exists
        existing = plant.schedules.filter(task_type=task_type, is_active=True).first()
        if existing:
            return Response(
                {'error': f'Schedule for {task_type} already exists'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create schedule
        schedule = Schedule.objects.create(
            plant=plant,
            task_type=task_type,
            frequency_days=frequency_days,
            next_due_date=date.today() + timedelta(days=frequency_days)
        )
        
        return Response(ScheduleSerializer(schedule).data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['delete'], url_path='schedules/(?P<schedule_id>[^/.]+)')
    def delete_schedule(self, request, pk=None, schedule_id=None):
        """
        DELETE /api/plants/{id}/schedules/{schedule_id}/ - Delete a schedule
        """
        plant = self.get_object()
        try:
            schedule = plant.schedules.get(id=schedule_id)
            schedule.is_active = False
            schedule.save()
            return Response({'message': 'Schedule deactivated'}, status=status.HTTP_200_OK)
        except Schedule.DoesNotExist:
            return Response({'error': 'Schedule not found'}, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=True, methods=['post'], url_path='photos/')
    def add_photo(self, request, pk=None):
        """
        POST /api/plants/{id}/photos/ - Add a photo to the plant gallery
        """
        plant = self.get_object()
        image_url = request.data.get('image_url')
        
        if not image_url:
            return Response({'error': 'image_url is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        photo = PlantPhoto.objects.create(
            plant=plant,
            image_url=image_url
        )
        
        # If this is the first photo, set it as cover
        if not plant.cover_photo:
            plant.cover_photo = photo
            plant.save()
        
        return Response(PlantPhotoSerializer(photo).data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['put'], url_path='photos/(?P<photo_id>[^/.]+)/set_cover/')
    def set_cover_photo(self, request, pk=None, photo_id=None):
        """
        PUT /api/plants/{id}/photos/{photo_id}/set_cover/ - Set a photo as the cover photo
        """
        plant = self.get_object()
        try:
            photo = plant.photos.get(id=photo_id)
            plant.cover_photo = photo
            plant.save()
            
            # Update is_cover flags
            plant.photos.update(is_cover=False)
            photo.is_cover = True
            photo.save()
            
            return Response({'message': 'Cover photo updated', 'photo': PlantPhotoSerializer(photo).data}, status=status.HTTP_200_OK)
        except PlantPhoto.DoesNotExist:
            return Response({'error': 'Photo not found'}, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=True, methods=['delete'], url_path='photos/(?P<photo_id>[^/.]+)')
    def delete_photo(self, request, pk=None, photo_id=None):
        """
        DELETE /api/plants/{id}/photos/{photo_id}/ - Delete a photo from the gallery
        """
        plant = self.get_object()
        try:
            photo = plant.photos.get(id=photo_id)
            
            # If this is the cover photo, set the first remaining photo as cover
            if plant.cover_photo == photo:
                remaining_photos = plant.photos.exclude(id=photo.id)
                if remaining_photos.exists():
                    plant.cover_photo = remaining_photos.first()
                    plant.cover_photo.is_cover = True
                    plant.cover_photo.save()
                    plant.save()
                else:
                    plant.cover_photo = None
                    plant.save()
            
            photo.delete()
            return Response({'message': 'Photo deleted'}, status=status.HTTP_200_OK)
        except PlantPhoto.DoesNotExist:
            return Response({'error': 'Photo not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def tasks_today(request):
    """
    GET /api/tasks/today - Returns all tasks due today or overdue
    """
    today = date.today()
    schedules = Schedule.objects.filter(
        plant__user=request.user,
        plant__is_dead=False,
        is_active=True,
        next_due_date__lte=today
    ).select_related('plant')
    
    tasks = []
    for schedule in schedules:
        tasks.append({
            'id': schedule.id,
            'plant_id': schedule.plant.id,
            'plant_name': schedule.plant.name,
            'task_type': schedule.task_type,
            'due_date': schedule.next_due_date,
            'frequency_days': schedule.frequency_days,
            'schedule_id': schedule.id,
            'is_overdue': schedule.next_due_date < today
        })
    
    # Sort: overdue first, then by due date
    tasks.sort(key=lambda x: (x['due_date'] >= today, x['due_date']))
    
    return Response(tasks, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_perenual(request):
    """
    GET /api/search/perenual?q=monstera - Proxy to Perenual API
    """
    query = request.GET.get('q', '')
    if not query:
        return Response({'error': 'Query parameter "q" is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Perenual API endpoint (you'll need to add your API key to settings)
    api_key = getattr(settings, 'PERENUAL_API_KEY', '')
    if not api_key:
        return Response({'error': 'Perenual API key not configured'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    url = f"https://perenual.com/api/species-list?key={api_key}&q={query}"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return Response(response.json(), status=status.HTTP_200_OK)
    except requests.RequestException as e:
        return Response({'error': f'Failed to fetch from Perenual: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset(request):
    """Request password reset via email"""
    email = request.data.get('email')
    if not email:
        return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        # Don't reveal if email exists for security
        return Response({'message': 'If an account exists with this email, a password reset link has been sent.'}, 
                       status=status.HTTP_200_OK)
    
    # Generate token
    token = default_token_generator.make_token(user)
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    
    # In production, send email with reset link
    reset_link = f"http://127.0.0.1:8000/api/password-reset-confirm/?uid={uid}&token={token}"
    
    return Response({
        'message': 'Password reset link sent to your email.',
        'reset_link': reset_link  # Remove in production
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def confirm_password_reset(request):
    """Confirm password reset with token"""
    uid = request.data.get('uid')
    token = request.data.get('token')
    new_password = request.data.get('password')
    
    if not all([uid, token, new_password]):
        return Response({'error': 'uid, token, and password are required'}, 
                       status=status.HTTP_400_BAD_REQUEST)
    
    try:
        user_id = force_str(urlsafe_base64_decode(uid))
        user = User.objects.get(pk=user_id)
    except (TypeError, ValueError, OverflowError, User.DoesNotExist):
        return Response({'error': 'Invalid reset link'}, status=status.HTTP_400_BAD_REQUEST)
    
    if not default_token_generator.check_token(user, token):
        return Response({'error': 'Invalid or expired reset token'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Validate and set new password
    from django.contrib.auth.password_validation import validate_password
    try:
        validate_password(new_password, user)
        user.set_password(new_password)
        user.save()
        return Response({'message': 'Password reset successfully'}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
