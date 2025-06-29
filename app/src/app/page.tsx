import { redirect } from "next/navigation";
import { cookies } from "next/headers";

export default async function Home() {
  const cookieStore = await cookies();
  const isAdmin = cookieStore.get("isAdmin")?.value === "true";

  if (isAdmin) {
    redirect("/in/admin/dashboard");
  } else {
    redirect("/in/usuario/cardapio");
  }
}
