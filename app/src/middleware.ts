import { NextRequest, NextResponse } from "next/server";

export function middleware(request: NextRequest) {
  const isAuthenticated =
    request.cookies.get("isAuthenticated")?.value === "true";

  if (request.nextUrl.pathname.startsWith("/in/") && !isAuthenticated) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  if (isAuthenticated && request.nextUrl.pathname === "/login") {
    return NextResponse.redirect(new URL("/in/dashboard", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/login", "/in/:path*"],
};
