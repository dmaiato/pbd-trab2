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

class PedidosSerializer(serializers.ModelSerializer):
  class Meta:
    model = Pedidos
    fields = '__all__'

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