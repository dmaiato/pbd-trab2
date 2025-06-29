import Header from "@/components/header";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <>
      <Header />
      <main className="min-h-screen bg-slate-800 flex items-center justify-center">
        {children}
      </main>
    </>
  );
}
