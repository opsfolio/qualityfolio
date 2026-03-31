import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Qualityfolio",
  description: "QA Assistant",
  icons: {
    icon: "https://qualityfolio.dev/favicon.png",
  },
};

import { TooltipProvider } from "@/components/ui/tooltip";

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="h-screen overflow-hidden">
        <TooltipProvider>{children}</TooltipProvider>
      </body>
    </html>
  );
}