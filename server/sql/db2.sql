DROP DATABASE IF EXISTS restaurante_db;
CREATE DATABASE restaurante_db;

\c restaurante_db;

DROP TABLE IF EXISTS usuarios CASCADE;
CREATE TABLE usuarios (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  senha VARCHAR(100) NOT NULL,
  is_admin BOOLEAN DEFAULT FALSE,
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

-- 0.1 Criar o JSONB que servirá de parâmetro em registrar_pedido
CREATE OR REPLACE FUNCTION criar_item_pedido_json(
    item_id_aux INT,
    quantidade_aux INT
) RETURNS JSONB AS $$
DECLARE
    item_json JSONB;
BEGIN
    -- Verifica se o item existe e está disponivel
    IF NOT EXISTS (SELECT 1 FROM itens_cardapio WHERE id = item_id_aux AND disponivel = TRUE) THEN
      RAISE EXCEPTION 'Item % não encontrado ou indisponível', item_id_aux;
    END IF;

    -- Cria o objeto JSONB
    item_json := jsonb_build_array(
        jsonb_build_object(
            'id', item_id_aux,
            'quantidade', quantidade_aux
        )
    );

    RETURN item_json;
END;
$$ LANGUAGE plpgsql;

-- 1. Registrar Pedido
CREATE OR REPLACE FUNCTION registrar_pedido(cliente_id_aux INT, itens_aux JSONB)
RETURNS INT AS $$
DECLARE
  novo_pedido_id_aux INT;
  total_aux DECIMAL(10,2) := 0;
  item_aux JSONB;
  item_id_aux INT;
  quantidade_aux INT;
  preco_aux DECIMAL(10,2);
BEGIN
  IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = cliente_id_aux) THEN
    RAISE EXCEPTION 'Cliente não encontrado';
  END IF;

  -- Cria um novo pedido com status 'em preparo'
  INSERT INTO pedidos (usuario_id, status_id, total)
  VALUES (cliente_id_aux, (SELECT id FROM status_pedidos WHERE nome = 'em preparo'), 0)
  RETURNING id INTO novo_pedido_id_aux;

  -- Verifica se a lista de itens está vazia
  FOR item_aux IN SELECT * FROM jsonb_array_elements(itens_aux)
  LOOP
    item_id_aux := (item_aux->>'id')::INT;
    quantidade_aux := (item_aux->>'quantidade')::INT;

    -- Verifica se o item existe e está disponível
    IF NOT EXISTS (SELECT 1 FROM itens_cardapio WHERE id = item_id_aux AND disponivel = TRUE) THEN
      RAISE EXCEPTION 'Item % não encontrado ou indisponível', item_id_aux;
    END IF; -- Essa verificação é feita na func criar_item_pedido_json, avaliar a possibilidade de usar a func no backend e deletar essa verificação duplicada.

    -- Obtém o preço do item
    SELECT preco INTO preco_aux FROM itens_cardapio WHERE id = item_id_aux;

    -- Insere o item no pedido
    INSERT INTO itens_pedido (pedido_id, item_id, quantidade, preco)
    VALUES (novo_pedido_id_aux, item_id_aux, quantidade_aux, preco_aux);

    -- Atualiza o total do pedido
    total_aux := total_aux + (preco_aux * quantidade_aux);

    -- Atualiza o estoque
    UPDATE estoque SET quantidade = quantidade - quantidade_aux WHERE item_id = item_id_aux;
  END LOOP;

  -- Atualiza o total do pedido
  UPDATE pedidos SET total = total_aux WHERE id = novo_pedido_id_aux;

  RETURN novo_pedido_id_aux;

EXCEPTION
  WHEN OTHERS THEN
    DELETE FROM pedidos WHERE id = novo_pedido_id_aux;
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- 2. Calcular Total do Pedido
CREATE OR REPLACE FUNCTION calcular_total_pedido(pedido_id_aux INT)
RETURNS DECIMAL(10,2) AS $$
DECLARE
  total_aux DECIMAL(10,2);
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pedidos WHERE id = pedido_id_aux) THEN
    RAISE EXCEPTION 'Pedido não encontrado';
  END IF;

  SELECT SUM(i.preco * i.quantidade) INTO total_aux 
  FROM itens_pedido i 
  WHERE i.pedido_id = pedido_id_aux;

  RETURN COALESCE(total_aux, 0);
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
CREATE OR REPLACE FUNCTION trocar_status_pedido(pedido_id INT, novo_status_id INT)
RETURNS VOID AS $$
DECLARE
  status_atual TEXT;
  novo_status_nome TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pedidos WHERE id = pedido_id) THEN
    RAISE EXCEPTION 'Pedido % não encontrado', pedido_id;
  END IF;

  SELECT s.nome INTO status_atual FROM pedidos p
  JOIN status_pedidos s ON p.status_id = s.id
  WHERE p.id = pedido_id;

  IF NOT EXISTS (SELECT 1 FROM status_pedidos WHERE id = novo_status_id) THEN
    RAISE EXCEPTION 'Status id % não encontrado', novo_status_id;
  END IF;

  SELECT nome INTO novo_status_nome FROM status_pedidos WHERE id = novo_status_id;

  IF (status_atual = 'em preparo' AND novo_status_nome NOT IN ('pronto', 'cancelado')) OR
     (status_atual = 'pronto' AND novo_status_nome NOT IN ('entregue', 'cancelado')) OR
     (status_atual = 'entregue' AND novo_status_nome != 'finalizado') THEN
    RAISE EXCEPTION 'Transição de status inválida de % para %', status_atual, novo_status_nome;
  END IF;

  UPDATE pedidos SET status_id = novo_status_id,
    atualizado_em = CURRENT_TIMESTAMP
  WHERE id = pedido_id;

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
    FORMAT('Pedido %s atualizado para "%s"', NEW.id, status_nome));
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
      FORMAT('Pedido %s cancelado em %s', NEW.id, CURRENT_TIMESTAMP));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_cancelamento
AFTER UPDATE OF status_id ON pedidos
FOR EACH ROW
EXECUTE FUNCTION log_cancelamento();



INSERT INTO usuarios (nome, email, senha, is_admin) VALUES
  ('usuario', 'usuario@gmail.com', 'senha123', FALSE),
  ('admin', 'admin@gmail.com', 'admin', TRUE);

INSERT INTO itens_cardapio (nome, descricao, preco) VALUES
  ('Pizza Margherita', 'Pizza com molho de tomate, mussarela e manjericao', 35.00),
  ('Hamburguer', 'Hamburguer artesanal com queijo e bacon', 28.50),
  ('Refrigerante', 'Lata de refrigerante 350ml', 6.00);

INSERT INTO estoque (item_id, quantidade) VALUES
  (1, 20),
  (2, 15),
  (3, 50);

INSERT INTO status_pedidos (nome, descricao) VALUES 
('em preparo', 'O seu pedido foi aceito por nós e estamos preparando'), 
('pronto','Seu pedido está pronto e já estamos providenciando a entrega'), 
('entregue','Pedido entregue para o cliente, pagamento pendente'), 
('finalizado','Pedido entregue para o cliente e pagamento concluído'),
('cancelado','Pedido foi cancelado, portanto retirado do processo');