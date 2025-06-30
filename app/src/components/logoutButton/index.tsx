"use client";

import { useRouter } from "next/navigation";

export default function LogoutButton() {
  const router = useRouter();

  function handleLogout() {
    document.cookie =
      "isAuthenticated=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    document.cookie =
      "isAdmin=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    router.push("/login");
  }

  return (
    <button
      onClick={handleLogout}
      className="bg-rose-500 py-1 px-2 rounded-sm text-gray-50 font-medium cursor-pointer"
    >
      Logout
    </button>
  );
}
