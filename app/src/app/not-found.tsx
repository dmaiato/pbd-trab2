import Link from "next/link";

export default function NotFound() {
  return (
    <main className="bg-gray-900 min-h-screen flex-1 flex flex-col gap-6 items-center justify-center">
      <div className="w-fit flex flex-col gap-6 items-center justify-center">
        <h1 className="text-gray-50 text-5xl self-start">{":("}</h1>
        <h1 className="text-gray-50 text-5xl">{"404 - Page not found."}</h1>
        <h3 className="text-2xl text-gray-50">
          Go back{" "}
          <Link
            href="/"
            className="underline underline-offset-2 text-slate-400"
          >
            home
          </Link>
        </h3>
      </div>
    </main>
  );
}
