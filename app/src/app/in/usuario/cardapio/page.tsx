import Link from "next/dist/client/link";

interface item {
  id: number;
  nome: string;
  descricao: string;
}

export default async function Cardapio() {
  const emojis = {
    pizza: "🍕",
    hamburguer: "🍔",
    refrigerante: "🥤",
  };

  let data: item[] = [];
  try {
    const response = await fetch("http://localhost:8000/api/cardapio/", {
      cache: "no-store",
    });
    if (!response.ok) throw new Error("Não foi possível carregar o cardápio");
    data = await response.json();
  } catch (error) {
    console.error(error);
  }

  return (
    <section className="bg-gray-50 rounded-sm p-4 w-md flex flex-col gap-3">
      <h1 className="text-gray-900 text-2xl">Cardápio</h1>
      <div className="flex flex-col space-y-4">
        <div className="flex flex-col space-y-2 divide-zinc-500 divide-y-1">
          {data.map((item: item) => {
            // Find the first emoji key that appears in the item's name
            const foundKey = Object.keys(emojis).find((key) =>
              item.nome.toLowerCase().includes(key)
            );
            return (
              <div key={item.id} className="pb-2">
                <h2 className="text-gray-800">
                  {emojis[foundKey as keyof typeof emojis] || "🍽️"} {item.nome}
                </h2>
                <p className="text-gray-600">{item.descricao}</p>
              </div>
            );
          })}
        </div>
        <Link
          href="/usuario/cardapio/novo"
          className="bg-emerald-700 text-gray-50 rounded-sm py-2 px-4 text-center hover:bg-emerald-600 transition-colors duration-200"
        >
          Página de pedido
        </Link>
      </div>
    </section>
  );
}
