"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";

export default function Login() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string>("");
  const router = useRouter();

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    try {
      const res = await fetch(
        `http://localhost:8000/api/usuarios/?username=${username}&password=${password}`
      );
      const data = await res.json();
      if (data && data.length > 0) {
        // Set a cookie and localStorage (unsecure, for demo only)
        document.cookie = "isAuthenticated=true; path=/";
        localStorage.setItem("isAuthenticated", "true");
        router.push("/in/dashboard");
      } else {
        setError("Credenciais inválidas.");
        console.log("deu ruim");
      }
    } catch (error) {}
  }

  return (
    <section className="min-w-screen min-h-screen bg-slate-900 flex items-center justify-center">
      <form
        className="w-2xs bg-gray-100 p-4 flex flex-col rounded-sm"
        onSubmit={handleLogin}
      >
        <input
          className="bg-gray-200 p-2 rounded-sm outline-0 mb-4"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          placeholder="Username"
        />
        <input
          className="bg-gray-200 p-2 rounded-sm outline-0 mb-4"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="Password"
          type="password"
        />
        <div className="h-6 text-rose-600 mb-2">{error && <p>{error}</p>}</div>
        <button
          className="bg-emerald-500 p-2 rounded-sm text-gray-50 font-medium cursor-pointer hover:bg-emerald-600"
          type="submit"
        >
          Login
        </button>
      </form>
    </section>
  );
}
