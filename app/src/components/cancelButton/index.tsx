"use client";

export default function CancelButton({
  id,
  className = "",
}: {
  id: number;
  className?: string;
}) {
  async function cancelarPedido(id: number) {
    try {
      const res = await fetch(
        `http://localhost:8000/api/usuario/pedidos/cancelar/?pedido_id=${id}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          cache: "no-store",
        }
      );
      if (!res.ok) {
        alert("Erro ao cancelar o pedido.");
      } else {
        // Recarrega a página para atualizar a lista de pedidos
        window.location.reload();
      }
    } catch {
      alert("Erro ao cancelar o pedido.");
    }
  }

  return (
    <button
      className={`bg-red-600 flex-none w-fit h-fit text-white px-4 py-2 rounded cursor-pointer hover:bg-red-500`}
      onClick={() => cancelarPedido(id)}
    >
      X
    </button>
  );
}
