"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";

export default function Header() {
  const router = useRouter();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    // checa os cookies pra verificar a autenticação
    const checkAuth = () => {
      const authCookie = document.cookie
        .split("; ")
        .find((row) => row.startsWith("isAuthenticated="));
      setIsAuthenticated(authCookie?.split("=")[1] === "true");

      const adminCookie = document.cookie
        .split("; ")
        .find((row) => row.startsWith("isAdmin="));
      setIsAdmin(adminCookie?.split("=")[1] === "true");
    };
    checkAuth();

    // adiciona um listener para verificar a autenticação quando a aba ganha foco
    window.addEventListener("focus", checkAuth);
    // limpa o listener quando o componente é desmontado (performance)
    return () => window.removeEventListener("focus", checkAuth);
  }, []);

  function handleLogout() {
    // limpa os cookies e redireciona para a página de login
    document.cookie =
      "isAuthenticated=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    document.cookie =
      "isAdmin=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    setIsAuthenticated(false);
    setIsAdmin(false);
    router.push("/login");
  }

  return (
    <header
      className={`h-12 ${
        isAdmin ? "bg-amber-950" : "bg-emerald-500"
      } flex items-center justify-around`}
    >
      <div>
        <Link href="/in/dashboard" className="text-gray-50 font-medium">
          Home
        </Link>
        <Link href="/in/pedidos"></Link>
      </div>
      <div className="w-4">
        {isAuthenticated && (
          <button
            onClick={handleLogout}
            className="bg-rose-500 py-1 px-2 rounded-sm text-gray-50 font-medium cursor-pointer"
          >
            Logout
          </button>
        )}
      </div>
    </header>
  );
}
