"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

interface CardapioItem {
  id: number;
  nome: string;
  descricao: string;
}

export default function CriarPedido() {
  const [cardapio, setCardapio] = useState<CardapioItem[]>([]);
  const [selected, setSelected] = useState<{ [id: number]: boolean }>({});
  const [quantidades, setQuantidades] = useState<{ [id: number]: number }>({});
  const [error, setError] = useState<string>("");
  const [success, setSuccess] = useState<string>("");
  const router = useRouter();

  useEffect(() => {
    fetch("http://localhost:8000/api/cardapio/")
      .then((res) => res.json())
      .then((data) => setCardapio(data))
      .catch(() => setError("Erro ao carregar o cardápio."));
  }, []);

  const handleSelectChange = (id: number, checked: boolean) => {
    setSelected((prev) => ({
      ...prev,
      [id]: checked,
    }));
    setQuantidades((prev) => ({
      ...prev,
      [id]: checked ? (prev[id] > 0 ? prev[id] : 1) : 0, // troca para 1 se marcado
    }));
  };

  const handleQuantidadeChange = (id: number, value: number) => {
    // Previne valores negativos ou zero
    const safeValue = value < 1 ? 1 : value;
    setQuantidades((prev) => ({
      ...prev,
      [id]: safeValue,
    }));
    if (safeValue > 0) {
      setSelected((prev) => ({
        ...prev,
        [id]: true,
      }));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setSuccess("");

    // pega o userId do cookie
    const userIdCookie = document.cookie
      .split("; ")
      .find((row) => row.startsWith("userId="));
    const userId = userIdCookie?.split("=")[1];

    if (!userId) {
      setError("Usuário não autenticado.");
      return;
    }

    // filtra os itens selecionados e suas quantidades
    const itens = cardapio
      .filter((item) => selected[item.id] && (quantidades[item.id] || 0) > 0)
      .map((item) => ({
        id: item.id,
        quantidade: quantidades[item.id] || 1,
      }));

    if (itens.length === 0) {
      setError("Selecione pelo menos um item e quantidade.");
      return;
    }

    try {
      const res = await fetch("http://localhost:8000/api/pedidos/registrar/", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          cliente_id: Number(userId),
          itens,
        }),
      });
      if (!res.ok) {
        const data = await res.json();
        setError(data.error || "Erro ao registrar pedido.");
        return;
      }
      setSuccess("Pedido registrado com sucesso!");
      setSelected({});
      setQuantidades({});
      setTimeout(() => router.push("/in/usuario/pedidos"), 1500);
    } catch {
      setError("Erro ao registrar pedido.");
    }
  };

  return (
    <section className="bg-gray-50 rounded-sm p-4 w-full max-w-lg mx-auto mt-8">
      <h1 className="text-gray-900 text-2xl mb-4">Criar Pedido</h1>
      <form onSubmit={handleSubmit} className="flex flex-col gap-4">
        {cardapio.map((item) => (
          <div key={item.id} className="flex items-center gap-4">
            <input
              type="checkbox"
              checked={!!selected[item.id]}
              onChange={(e) => handleSelectChange(item.id, e.target.checked)}
            />
            <div className="flex-1">
              <div className="font-medium">{item.nome}</div>
              <div className="text-sm text-gray-600">{item.descricao}</div>
            </div>
            {selected[item.id] && (
              <input
                type="number"
                min={1}
                value={quantidades[item.id] || 1}
                onChange={(e) =>
                  handleQuantidadeChange(item.id, Number(e.target.value))
                }
                className="w-16 border rounded px-2 py-1"
              />
            )}
          </div>
        ))}
        {error && <div className="text-red-600">{error}</div>}
        {success && <div className="text-green-600">{success}</div>}
        <button
          type="submit"
          className="bg-emerald-500 text-white px-4 py-2 rounded hover:bg-emerald-600"
        >
          Registrar Pedido
        </button>
      </form>
    </section>
  );
}
