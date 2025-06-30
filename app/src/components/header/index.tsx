import Link from "next/link";
import { cookies } from "next/headers";
import LogoutButton from "../logoutButton";

export default async function Header() {
  const cookieStore = await cookies();
  const isAdmin = cookieStore.get("isAdmin")?.value === "true";
  const homeHref = isAdmin ? "/in/admin/dashboard" : "/in/usuario/cardapio";

  const headerOptionStyle =
    "text-gray-50 font-medium pr-2.5 hover:underline underline-offset-2";

  return (
    <header
      className={`h-12 ${
        isAdmin ? "bg-teal-700" : "bg-emerald-500"
      } flex items-center justify-between px-16`}
    >
      <div className="flex items-center gap-x-3 divide-x">
        <Link href={homeHref} className={headerOptionStyle}>
          Home
        </Link>
        {!isAdmin && (
          <>
            <Link href="/in/usuario/criar_pedido" className={headerOptionStyle}>
              Criar pedido
            </Link>
            <Link href="/in/usuario/pedidos" className={headerOptionStyle}>
              Meus pedidos
            </Link>
          </>
        )}
        {isAdmin && (
          <Link href="/in/pedidos" className={headerOptionStyle}>
            Pedidos
          </Link>
        )}
      </div>
      <LogoutButton />
    </header>
  );
}
