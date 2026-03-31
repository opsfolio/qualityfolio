"use client";

import { AssistantRuntimeProvider } from "@assistant-ui/react";
import { useChatRuntime, AssistantChatTransport } from "@assistant-ui/react-ai-sdk";
import { Thread } from "@/components/assistant-ui/thread";
import { SUGGESTIONS } from "@/lib/suggestions";
import { BotIcon, SparklesIcon } from "lucide-react";

export default function EmbedPage() {
  const runtime = useChatRuntime({
    transport: new AssistantChatTransport({ api: "/api/chat" }),
  });

  return (
    <div className="h-screen w-full bg-background flex flex-col border-none overflow-hidden">
      {/* Premium Header */}
      <div className="flex items-center justify-between px-4 py-2 border-b bg-muted/30">
        <div className="flex items-center gap-2">
          <div className="size-8 rounded-lg bg-white overflow-hidden flex items-center justify-center shadow-sm border border-border/20 p-0.5">
            <img 
              src="https://qualityfolio.dev/favicon.png" 
              alt="Qualityfolio" 
              className="size-full object-contain"
            />
          </div>
          <div>
            <h1 className="text-sm font-semibold text-foreground leading-none font-serif">Qualityfolio AI</h1>
            <p className="text-[10px] text-muted-foreground mt-1 flex items-center gap-1 font-serif">
              <SparklesIcon className="size-2 text-primary" /> active
            </p>
          </div>
        </div>
      </div>

      {/* Chat Thread */}
      <div className="flex-1 overflow-hidden">
        <AssistantRuntimeProvider runtime={runtime}>
          <Thread />
        </AssistantRuntimeProvider>
      </div>
    </div>
  );
}
