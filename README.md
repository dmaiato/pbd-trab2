# Restaurante API & Frontend

Este projeto é um sistema completo para gerenciamento de pedidos de restaurante, incluindo backend (API RESTful em Django + PostgreSQL) e frontend (Next.js + React).

## Tecnologias Utilizadas

- **Backend**
  - [Python 3.11+](https://www.python.org/)
  - [Django 4+](https://www.djangoproject.com/)
  - [Django REST Framework](https://www.django-rest-framework.org/)
  - [PostgreSQL](https://www.postgresql.org/)
- **Frontend**
  - [Next.js 14+](https://nextjs.org/)
  - [React 18+](https://react.dev/)
  - [Tailwind CSS](https://tailwindcss.com/)
- **Outros**
  - [psycopg2](https://pypi.org/project/psycopg2/) (driver PostgreSQL para Python)
  - [Node.js 18+](https://nodejs.org/) (para rodar o frontend)

---

## Como Inicializar o Projeto

### 1. Clone o repositório

```bash
git clone <url-do-repositorio>
cd <nome-da-pasta>
```

### 2. Backend (Django)

#### a) Crie e ative um ambiente virtual

```bash
python -m venv venv
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate
```

#### b) Instale as dependências

```bash
pip install -r requirements.txt
```

#### c) Configure o banco de dados

- Crie o banco de dados PostgreSQL (exemplo: `restaurante_db`)
- Edite o arquivo `settings.py` com suas credenciais do banco

#### d) Execute as migrações

```bash
python manage.py migrate
```

#### e) (Opcional) Popule o banco com dados iniciais

```bash
python manage.py loaddata fixtures/*.json
# ou use os scripts SQL em `server/sql/db2.sql`
```

#### f) Inicie o servidor backend

```bash
python manage.py runserver
```

---

### 3. Frontend (Next.js)

#### a) Instale as dependências

```bash
cd app
npm install
```

#### b) Inicie o servidor frontend

```bash
npm run dev
```

O frontend estará disponível em `http://localhost:3000` e o backend em `http://localhost:8000`.

---

## Principais Dependências

### Backend

- Django
- djangorestframework
- psycopg2
- python-dotenv (opcional para variáveis de ambiente)

### Frontend

- next
- react
- tailwindcss

---

## Observações

- Certifique-se de que o PostgreSQL está rodando e acessível.
- As URLs da API podem ser ajustadas em arquivos de configuração do frontend.
- Para desenvolvimento local, use as URLs `http://localhost:8000` (API) e `http://localhost:3000` (frontend).
