from django.urls import path
from . import views

urlpatterns = [
    path('usuarios/', views.UsuariosAuthView.as_view(), name='usuarios_auth'),
    path('cardapio/', views.ItensCardapioListView.as_view(), name='itens_cardapio_list'),
    path('pedidos/registrar/', views.RegistrarPedidoView.as_view(), name='registrar_pedido'),
    path('usuario/pedidos/', views.PedidosPorUsuarioListView.as_view(), name='pedidos_por_usuario'),
    path('usuario/pedidos/cancelar/', views.CancelarPedidoView.as_view(), name='cancelar_pedido'),
    path('usuario/pedidos/<int:id>/', views.DetalharPedidoView.as_view(), name='detalhar_pedido'),   
]
