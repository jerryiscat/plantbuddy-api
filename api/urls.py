from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenVerifyView,
)
from .views import (
    UserViewSet, PlantViewSet, CustomTokenObtainPairView,
    request_password_reset, confirm_password_reset,
    tasks_today, search_perenual
)

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'plants', PlantViewSet)

urlpatterns = [
    path('', include(router.urls)),
    
    # Authentication
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    path('password-reset/', request_password_reset, name='password_reset'),
    path('password-reset-confirm/', confirm_password_reset, name='password_reset_confirm'),
    
    # Tasks
    path('tasks/today/', tasks_today, name='tasks_today'),
    
    # External Data
    path('search/perenual/', search_perenual, name='search_perenual'),
]