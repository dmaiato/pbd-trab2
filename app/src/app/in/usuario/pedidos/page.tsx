import CancelButton from "@/components/cancelButton";
import Link from "next/link";
import { cookies } from "next/headers";

interface Pedido {
  id: number;
  status_id: number;
  total: number;
  criado_em: string;
  status_nome?: string;
}

export default async function ListarPedidos() {
  const cookieStore = await cookies();
  const userId = cookieStore.get("userId")?.value;

  let pedidos: Pedido[] = [];
  let error = "";

  if (!userId) {
    error = "Usuário não autenticado.";
  } else {
    try {
      const res = await fetch(
        `http://localhost:8000/api/usuario/pedidos/?usuario_id=${userId}`,
        { cache: "no-store" }
      );
      if (!res.ok) {
        error = "Erro ao carregar pedidos.";
      } else {
        pedidos = await res.json();
      }
    } catch {
      error = "Erro ao carregar pedidos.";
    }
  }

  const pedidosCancelados = pedidos.filter(
    (pedido) => pedido.status_nome === "cancelado"
  );
  const pedidosAtivos = pedidos.filter(
    (pedido) => pedido.status_nome !== "cancelado"
  );

  return (
    <section className="bg-gray-50 rounded-sm p-6 w-lg flex flex-col gap-4">
      <h1 className="text-gray-900 text-2xl">Meus Pedidos</h1>
      {error && <p className="text-red-600">{error}</p>}

      {!error && pedidosAtivos.length === 0 && (
        <p className="text-gray-600">Nenhum pedido ativo encontrado.</p>
      )}

      {!error && pedidosAtivos.length > 0 && (
        <>
          <h2 className="text-lg font-semibold mt-2">Pedidos Ativos</h2>
          <ul className="flex flex-col gap-2">
            {pedidosAtivos.map((pedido) => (
              <li
                key={pedido.id}
                className="border-b border-gray-200 py-2 flex items-center gap-4"
              >
                <div className="flex-1">
                  <div>
                    <span className="font-medium">Pedido #{pedido.id}</span> -
                    Total: R$ {pedido.total}
                  </div>
                  <div className="text-sm text-gray-500">
                    Status: {pedido.status_nome} | Criado em:{" "}
                    {new Date(pedido.criado_em).toLocaleString()}
                  </div>
                </div>
                <div className="flex gap-2">
                  <Link
                    href={`/in/usuario/pedidos/detalhes/${pedido.id}`}
                    className="px-3.5 py-2 bg-emerald-600 flex items-center justify-center rounded-sm font-bold text-white"
                  >
                    {">"}
                  </Link>
                  <CancelButton id={pedido.id} />
                </div>
              </li>
            ))}
          </ul>
        </>
      )}

      {!error && pedidosCancelados.length > 0 && (
        <>
          <h2 className="text-lg font-semibold mt-6">Pedidos Cancelados</h2>
          <ul className="flex flex-col gap-2">
            {pedidosCancelados.map((pedido) => (
              <li key={pedido.id} className="py-2 opacity-60">
                <div>
                  <span className="font-medium">Pedido #{pedido.id}</span> -
                  Total: R$ {pedido.total}
                </div>
                <div className="text-sm text-gray-500">
                  Status: {pedido.status_nome} | Criado em:{" "}
                  {new Date(pedido.criado_em).toLocaleString()}
                </div>
              </li>
            ))}
          </ul>
        </>
      )}
    </section>
  );
}
