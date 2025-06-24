from rest_framework import generics
from .models import Usuarios
from .serializers import UsuariosSerializer

class UsuariosListView(generics.ListAPIView):
  queryset = Usuarios.objects.all()
  serializer_class = UsuariosSerializer