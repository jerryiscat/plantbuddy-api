from django.contrib import admin
from .models import User, Plant, Schedule, ActivityLog, PlantPhoto

admin.site.register(User)
admin.site.register(Plant)
admin.site.register(Schedule)
admin.site.register(ActivityLog)
admin.site.register(PlantPhoto)
