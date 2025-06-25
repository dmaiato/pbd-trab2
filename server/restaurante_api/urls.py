from django.urls import path
from . import views

urlpatterns = [
    path('usuarios/all', views.UsuariosListView.as_view(), name='usuarios_list'),
    path('usuarios/', views.UsuariosAuthView.as_view(), name='usuarios_auth')
    
]
