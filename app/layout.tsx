import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Satera Core",
  description: "Shared platform backbone for collectible asset products",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
