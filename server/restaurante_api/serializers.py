from rest_framework import serializers
from .models import Usuarios, StatusPedidos, Pedidos, ItensCardapio, ItensPedido, Estoque, Logs

class UsuariosSerializer(serializers.ModelSerializer):
  class Meta:
    model = Usuarios
    fields = '__all__'

class StatusPedidosSerializer(serializers.ModelSerializer):
  class Meta:
    model = StatusPedidos
    fields = '__all__'
    
class ItensPedidoWithNomeSerializer(serializers.ModelSerializer):
  nome = serializers.CharField(source="item.nome", read_only=True)

  class Meta:
    model = ItensPedido
    fields = ['id', 'item', 'nome', 'quantidade', 'preco']

class PedidosSerializer(serializers.ModelSerializer):
  status_nome = serializers.CharField(source="status.nome", read_only=True)
  itens = ItensPedidoWithNomeSerializer(many=True, read_only=True)

  class Meta:
    model = Pedidos
    fields = ['id', 'usuario', 'status', 'status_nome', 'total', 'criado_em', 'atualizado_em', 'itens']

class ItensCardapioSerializer(serializers.ModelSerializer):
  class Meta:
    model = ItensCardapio
    fields = '__all__'

class ItensPedidoSerializer(serializers.ModelSerializer):
  class Meta:
    model = ItensPedido
    fields = '__all__'

class EstoqueSerializer(serializers.ModelSerializer):
  class Meta:
    model = Estoque
    fields = '__all__'

class LogsSerializer(serializers.ModelSerializer):
  class Meta:
    model = Logs
    fields = '__all__'