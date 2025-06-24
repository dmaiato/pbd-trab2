DROP DATABASE IF EXISTS restaurante_db;
CREATE DATABASE restaurante_db;

\c restaurante_db;

DROP TABLE IF EXISTS usuarios CASCADE;
CREATE TABLE usuarios (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  senha VARCHAR(100) NOT NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS status_pedidos CASCADE;
CREATE TABLE status_pedidos (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(50) NOT NULL UNIQUE,
  descricao TEXT,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS itens_cardapio CASCADE;
CREATE TABLE itens_cardapio (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  descricao TEXT,
  preco DECIMAL(10,2) NOT NULL,
  disponivel BOOLEAN DEFAULT TRUE,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS pedidos CASCADE;
CREATE TABLE pedidos (
  id SERIAL PRIMARY KEY,
  usuario_id INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  status_id INT REFERENCES status_pedidos(id) ON DELETE SET NULL,
  total DECIMAL(10,2) NOT NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS itens_pedido CASCADE;
CREATE TABLE itens_pedido (
  id SERIAL PRIMARY KEY,
  pedido_id INT NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  item_id INT NOT NULL REFERENCES itens_cardapio(id) ON DELETE CASCADE,
  quantidade INT NOT NULL,
  preco DECIMAL(10,2) NOT NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS estoque CASCADE;
CREATE TABLE estoque (
  id SERIAL PRIMARY KEY,
  item_id INT NOT NULL REFERENCES itens_cardapio(id) ON DELETE CASCADE,
  quantidade INT NOT NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS logs CASCADE;
CREATE TABLE logs (
  id SERIAL PRIMARY KEY,
  usuario_id INT REFERENCES usuarios(id) ON DELETE CASCADE,
  acao VARCHAR(255) NOT NULL,
  descricao TEXT,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- FUNÇÕES

-- 1. Registrar Pedido
CREATE OR REPLACE FUNCTION registrar_pedido(cliente_id INT, itens JSONB)
RETURNS INT AS $$
DECLARE
  novo_pedido_id INT;
  total DECIMAL(10,2) := 0;
  item JSONB;
  item_id INT;
  quantidade INT;
  preco DECIMAL(10,2);
BEGIN
  IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = cliente_id) THEN
    RAISE EXCEPTION 'Cliente não encontrado';
  END IF;

  INSERT INTO pedidos (usuario_id, status_id, total)
  VALUES (cliente_id, (SELECT id FROM status_pedidos WHERE nome = 'em preparo'), 0)
  RETURNING id INTO novo_pedido_id;

  FOR item IN SELECT * FROM jsonb_array_elements(itens)
  LOOP
    item_id := (item->>'id')::INT;
    quantidade := (item->>'quantidade')::INT;
    preco := (item->>'preco')::DECIMAL;

    IF NOT EXISTS (SELECT 1 FROM itens_cardapio WHERE id = item_id AND disponivel = TRUE) THEN
      RAISE EXCEPTION 'Item % não encontrado ou indisponível', item_id;
    END IF;

    IF (SELECT quantidade FROM estoque WHERE item_id = item_id) < quantidade THEN
      RAISE EXCEPTION 'Estoque insuficiente para o item %', item_id;
    END IF;

    INSERT INTO itens_pedido (pedido_id, item_id, quantidade, preco)
    VALUES (novo_pedido_id, item_id, quantidade, preco);

    total := total + (preco * quantidade);

    UPDATE estoque SET quantidade = quantidade - quantidade WHERE item_id = item_id;
  END LOOP;

  UPDATE pedidos SET total = total WHERE id = novo_pedido_id;

  RETURN novo_pedido_id;

EXCEPTION
  WHEN OTHERS THEN
    DELETE FROM pedidos WHERE id = novo_pedido_id;
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- 2. Calcular Total do Pedido
CREATE OR REPLACE FUNCTION calcular_total_pedido(pedido_id INT)
RETURNS DECIMAL(10,2) AS $$
DECLARE
  total DECIMAL(10,2);
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pedidos WHERE id = pedido_id) THEN
    RAISE EXCEPTION 'Pedido não encontrado';
  END IF;

  SELECT SUM(i.preco * i.quantidade) INTO total FROM itens_pedido i WHERE i.pedido_id = pedido_id;

  RETURN COALESCE(total, 0);
END;
$$ LANGUAGE plpgsql;

-- 3. Listar Pedidos por Status
CREATE OR REPLACE FUNCTION listar_pedidos(status TEXT)
RETURNS TABLE(id INT, usuario_id INT, status_id INT, total DECIMAL(10,2), criado_em TIMESTAMP) AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM status_pedidos WHERE nome = status) THEN
    RAISE EXCEPTION 'Status % não encontrado', status;
  END IF;

  RETURN QUERY
  SELECT p.id, p.usuario_id, p.status_id, p.total, p.criado_em
  FROM pedidos p
  JOIN status_pedidos s ON p.status_id = s.id
  WHERE s.nome = status;
END;
$$ LANGUAGE plpgsql;

-- 4. Trocar Status do Pedido
CREATE OR REPLACE FUNCTION trocar_status_pedido(pedido_id INT, novo_status TEXT)
RETURNS VOID AS $$
DECLARE
  status_atual TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pedidos WHERE id = pedido_id) THEN
    RAISE EXCEPTION 'Pedido % não encontrado', pedido_id;
  END IF;

  SELECT s.nome INTO status_atual FROM pedidos p
  JOIN status_pedidos s ON p.status_id = s.id
  WHERE p.id = pedido_id;

  IF NOT EXISTS (SELECT 1 FROM status_pedidos WHERE nome = novo_status) THEN
    RAISE EXCEPTION 'Status % não encontrado', novo_status;
  END IF;

  IF (status_atual = 'em preparo' AND novo_status NOT IN ('pronto', 'cancelado')) OR
     (status_atual = 'pronto' AND novo_status NOT IN ('entregue', 'cancelado')) OR
     (status_atual = 'entregue' AND novo_status != 'finalizado') THEN
    RAISE EXCEPTION 'Transição de status inválida de % para %', status_atual, novo_status;
  END IF;

  UPDATE pedidos SET status_id = (SELECT id FROM status_pedidos WHERE nome = novo_status),
    atualizado_em = CURRENT_TIMESTAMP
  WHERE id = pedido_id;

  INSERT INTO logs (usuario_id, acao, descricao)
  VALUES (
    (SELECT usuario_id FROM pedidos WHERE id = pedido_id),
    'trocar_status_pedido',
    FORMAT('Pedido % alterado de % para %', pedido_id, status_atual, novo_status)
  );
END;
$$ LANGUAGE plpgsql;

-- TRIGGERS

-- 1. Log de Alteração de Pedido
CREATE OR REPLACE FUNCTION log_alteracao_pedido()
RETURNS TRIGGER AS $$
DECLARE
  status_nome TEXT;
BEGIN
  SELECT nome INTO status_nome FROM status_pedidos WHERE id = NEW.status_id;
  INSERT INTO logs (usuario_id, acao, descricao)
  VALUES (NEW.usuario_id, 'alteracao_pedido',
    FORMAT('Pedido % atualizado para "%s" em %s', NEW.id, status_nome, CURRENT_TIMESTAMP));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_alteracao
AFTER UPDATE ON pedidos
FOR EACH ROW
EXECUTE FUNCTION log_alteracao_pedido();

-- 2. Validação de Estoque antes de inserir item_pedido
CREATE OR REPLACE FUNCTION validar_estoque()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM estoque WHERE item_id = NEW.item_id) THEN
    RAISE EXCEPTION 'Item % não encontrado no estoque', NEW.item_id;
  END IF;
  IF (SELECT quantidade FROM estoque WHERE item_id = NEW.item_id) < NEW.quantidade THEN
    RAISE EXCEPTION 'Estoque insuficiente para o item %', NEW.item_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_estoque
BEFORE INSERT ON itens_pedido
FOR EACH ROW
EXECUTE FUNCTION validar_estoque();

-- 3. Descontar Estoque após inserir item_pedido
CREATE OR REPLACE FUNCTION descontar_estoque()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE estoque SET quantidade = quantidade - NEW.quantidade WHERE item_id = NEW.item_id;
  IF (SELECT quantidade FROM estoque WHERE item_id = NEW.item_id) < 0 THEN
    RAISE EXCEPTION 'Estoque negativo para o item %', NEW.item_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_descontar_estoque
AFTER INSERT ON itens_pedido
FOR EACH ROW
EXECUTE FUNCTION descontar_estoque();

-- 4. Validação de Transição de Status
CREATE OR REPLACE FUNCTION validar_transicao_status()
RETURNS TRIGGER AS $$
DECLARE
  status_atual TEXT;
  status_finalizado INT := (SELECT id FROM status_pedidos WHERE nome = 'finalizado');
  status_reativado INT := (SELECT id FROM status_pedidos WHERE nome = 'reativado');
BEGIN
  SELECT s.nome INTO status_atual FROM pedidos p
  JOIN status_pedidos s ON p.status_id = s.id
  WHERE p.id = NEW.id;

  IF (status_atual = 'entregue' AND NEW.status_id != status_finalizado) OR
     (status_atual = 'cancelado' AND NEW.status_id != status_reativado) THEN
    RAISE EXCEPTION 'Não é possível alterar um pedido já %', status_atual;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_status
BEFORE UPDATE OF status_id ON pedidos
FOR EACH ROW
EXECUTE FUNCTION validar_transicao_status();

-- 5. Log de Cancelamento
CREATE OR REPLACE FUNCTION log_cancelamento()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status_id = (SELECT id FROM status_pedidos WHERE nome = 'cancelado') THEN
    INSERT INTO logs (usuario_id, acao, descricao)
    VALUES (NEW.usuario_id, 'cancelamento_pedido',
      FORMAT('Pedido % cancelado em %s', NEW.id, CURRENT_TIMESTAMP));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_cancelamento
AFTER UPDATE OF status_id ON pedidos
FOR EACH ROW
EXECUTE FUNCTION log_cancelamento();



INSERT INTO usuarios (nome, email, senha) VALUES
  ('usuario', 'usuario@gmail.com', 'senha123');

INSERT INTO itens_cardapio (nome, descricao, preco) VALUES
  ('Pizza Margherita', 'Pizza com molho de tomate, mussarela e manjericao', 35.00),
  ('Hamburguer', 'Hamburguer artesanal com queijo e bacon', 28.50),
  ('Refrigerante', 'Lata de refrigerante 350ml', 6.00);

INSERT INTO estoque (item_id, quantidade) VALUES
  (1, 20),
  (2, 15),
  (3, 50);

