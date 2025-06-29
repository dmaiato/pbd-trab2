"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";

export default function Header() {
  const router = useRouter();

  function handleLogout() {
    // limpas os cookies
    document.cookie =
      "isAuthenticated=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    document.cookie =
      "isAdmin=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    router.push("/login");
  }

  // lê o admin uma vez ao carregar a página (sem estado/rerendering)
  const adminCookie =
    typeof document !== "undefined"
      ? document.cookie.split("; ").find((row) => row.startsWith("isAdmin="))
      : undefined;
  const isAdmin = adminCookie?.split("=")[1] === "true";

  const homeHref = isAdmin ? "/in/admin/dashboard" : "/in/usuario/cardapio";

  return (
    <header
      className={`h-12 ${
        isAdmin ? "bg-teal-700" : "bg-emerald-500"
      } flex items-center justify-around`}
    >
      <div>
        <Link href={homeHref} className="text-gray-50 font-medium">
          Home
        </Link>
        <Link href="/in/pedidos"></Link>
      </div>
      <div className="w-4">
        <button
          onClick={handleLogout}
          className="bg-rose-500 py-1 px-2 rounded-sm text-gray-50 font-medium cursor-pointer"
        >
          Logout
        </button>
      </div>
    </header>
  );
}
