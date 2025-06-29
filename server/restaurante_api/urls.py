from django.urls import path
from . import views

urlpatterns = [
    path('usuarios/', views.UsuariosAuthView.as_view(), name='usuarios_auth'),
    path('cardapio/', views.ItensCardapioListView.as_view(), name='itens_cardapio_list')
]
