import { NextRequest, NextResponse } from "next/server";

export function middleware(request: NextRequest) {
  const isAuthenticated =
    request.cookies.get("isAuthenticated")?.value === "true";
  const isAdmin = request.cookies.get("isAdmin")?.value === "true";

  // protege todas as rotas /in/*
  if (request.nextUrl.pathname.startsWith("/in/") && !isAuthenticated) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  // protege rotas apenas para admin
  if (request.nextUrl.pathname.startsWith("/in/admin") && !isAdmin) {
    return NextResponse.redirect(new URL("/in/dashboard", request.url));
  }

  // impede que usuários logados acessem /login
  if (isAuthenticated && request.nextUrl.pathname === "/login") {
    return NextResponse.redirect(new URL("/in/dashboard", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/login", "/in/:path*"],
};
