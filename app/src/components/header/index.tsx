"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";

export default function Header() {
  const router = useRouter();
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    // Check authentication status on mount
    const authCookie = document.cookie
      .split("; ")
      .find((row) => row.startsWith("isAuthenticated="));
    setIsAuthenticated(
      authCookie?.split("=")[1] === "true" ||
        localStorage.getItem("isAuthenticated") === "true"
    );
  }, []);

  function handleLogout() {
    document.cookie =
      "isAuthenticated=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    localStorage.removeItem("isAuthenticated");
    setIsAuthenticated(false);
    router.push("/login");
  }

  return (
    <header className="h-12 bg-emerald-500 flex items-center justify-around">
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
