from django.urls import path
from .views import UsuariosListView

urlpatterns = [
    path('usuarios/', UsuariosListView.as_view(), name='usuarios_list')
]
