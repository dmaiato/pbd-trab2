import { notFound } from "next/navigation";
import Link from "next/link";

export default async function PedidoDetalhe({
  params,
}: {
  params: { id: string };
}) {
  const res = await fetch(
    `http://localhost:8000/api/usuario/pedidos/${params.id}/`,
    {
      cache: "no-store",
    }
  );

  if (!res.ok) {
    notFound();
  }

  const pedido = await res.json();

  return (
    <section className="w-lg mx-auto bg-white rounded-lg shadow p-6 mt-8">
      <Link
        href="/in/usuario/pedidos"
        className="inline-block mb-4 px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300 transition"
      >
        ← Voltar para pedidos
      </Link>
      <h1 className="text-2xl font-bold text-gray-800 mb-2">
        Detalhes do Pedido <span className="text-blue-600">#{pedido.id}</span>
      </h1>
      <div className="mb-4 space-y-1">
        <p>
          <span className="font-semibold">Status:</span>{" "}
          <span className="text-blue-700">{pedido.status_nome}</span>
        </p>
        <p>
          <span className="font-semibold">Total:</span>{" "}
          <span className="text-green-700">R$ {pedido.total}</span>
        </p>
        <p>
          <span className="font-semibold">Criado em:</span>{" "}
          {new Date(pedido.criado_em).toLocaleString()}
        </p>
        <p>
          <span className="font-semibold">Atualizado em:</span>{" "}
          {new Date(pedido.atualizado_em).toLocaleString()}
        </p>
      </div>
      <h2 className="mt-6 mb-2 text-lg font-semibold text-gray-700">
        Itens do Pedido
      </h2>
      <ul className="space-y-3">
        {pedido.itens && pedido.itens.length > 0 ? (
          pedido.itens.map((item: any) => (
            <li
              key={item.id}
              className="border rounded p-3 bg-gray-50 flex flex-col"
            >
              <div>
                <span className="font-medium text-gray-900">{item.nome}</span>
              </div>
              <div className="text-sm text-gray-700 mt-1 sm:mt-0">
                Quantidade:{" "}
                <span className="font-semibold">{item.quantidade}</span> | Preço
                unitário: <span className="font-semibold">R$ {item.preco}</span>
              </div>
            </li>
          ))
        ) : (
          <li className="text-gray-500 italic">
            Nenhum item encontrado neste pedido.
          </li>
        )}
      </ul>
    </section>
  );
}
