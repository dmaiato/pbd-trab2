from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import generics, status
from django.db import connection
import json
from .models import ItensCardapio, Usuarios
from .serializers import ItensCardapioSerializer, UsuariosSerializer

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