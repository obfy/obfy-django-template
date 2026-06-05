from django.urls import path

from core.views import quote

urlpatterns = [
    path("", quote, name="quote"),
]
