from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import generics
from .models import Usuarios
from .serializers import UsuariosSerializer

class UsuariosListView(generics.ListAPIView):
  queryset = Usuarios.objects.all()
  serializer_class = UsuariosSerializer

# crimes de segurança
class UsuariosAuthView(APIView):
  def get(self, request):
    username = request.GET.get("username")
    password = request.GET.get("password")
    if not username or not password:
        return Response([])  # Return empty if params missing

    user = Usuarios.objects.filter(nome=username, senha=password).first()
    if user:
        serializer = UsuariosSerializer(user)
        return Response([serializer.data])  # Return as a list for frontend compatibility
    return Response([])