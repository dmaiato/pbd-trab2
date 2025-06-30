from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import generics, status
from django.db import connection
import json
from .models import ItensCardapio, Pedidos, StatusPedidos, Usuarios
from .serializers import ItensCardapioSerializer, PedidosSerializer, UsuariosSerializer

# crimes de segurança
class UsuariosAuthView(APIView):
  def get(self, request):
    username = request.GET.get("username")
    password = request.GET.get("password")
    if not username or not password:
        return Response([])

    user = Usuarios.objects.filter(nome=username, senha=password).first()
    if user:
        serializer = UsuariosSerializer(user)
        return Response([serializer.data])
    return Response([])
  
# endopoint para listar itens do cardápio
class ItensCardapioListView(generics.ListAPIView):
    queryset = ItensCardapio.objects.all()
    serializer_class = ItensCardapioSerializer
    
class RegistrarPedidoView(APIView):
    def post(self, request):
        try:
            cliente_id = request.data.get("cliente_id")
            itens = request.data.get("itens")  # lista de itens do pedido
            if not cliente_id or not itens:
                return Response({"error": "cliente_id and itens are required"}, status=status.HTTP_400_BAD_REQUEST)

            # Verifica se o cliente existe
            itens_json = json.dumps(itens)

            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT 1 FROM usuarios WHERE id = %s;",
                    [cliente_id]
                )
                if not cursor.fetchone():
                    return Response({"error": "Cliente não encontrado"}, status=status.HTTP_404_NOT_FOUND)

            itens_json = json.dumps(itens) # Converte a lista de itens para JSON

            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT registrar_pedido(%s, %s::jsonb);",
                    [cliente_id, itens_json]
                )
                novo_pedido_id = cursor.fetchone()[0]

            return Response({"pedido_id": novo_pedido_id}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

# Endpoint para listar pedidos por usuário
class PedidosPorUsuarioListView(generics.ListAPIView):
    serializer_class = PedidosSerializer

    def get_queryset(self):
        usuario_id = self.request.query_params.get("usuario_id")
        if usuario_id is not None:
            return Pedidos.objects.filter(usuario_id=usuario_id).select_related("status")
        return Pedidos.objects.none()

class DetalharPedidoView(APIView):
    def get(self, request, id):
        try:
            pedido = (
                Pedidos.objects
                .select_related("status", "usuario")
                .prefetch_related("itens__item")
                .get(id=id)
            )
            serializer = PedidosSerializer(pedido)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Pedidos.DoesNotExist:
            return Response({"error": "Pedido não encontrado"}, status=status.HTTP_404_NOT_FOUND)

class CancelarPedidoView(APIView):
    def post(self, request):
        pedido_id = request.query_params.get("pedido_id")
        if not pedido_id:
            return Response({"error": "pedido_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            # Verifica se o pedido existe
            status_cancelado = StatusPedidos.objects.get(nome="cancelado")
            status_cancelado_id = status_cancelado.id
            print(status_cancelado_id)

            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT trocar_status_pedido(%s, %s);",
                    [pedido_id, status_cancelado_id]
                )
            print('nada errado aqui 2')
            return Response({"success": f"Pedido {pedido_id} cancelado com sucesso."})
        except StatusPedidos.DoesNotExist:
            return Response({"error": "Status 'cancelado' não encontrado"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)