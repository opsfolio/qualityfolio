"use client";

import { useChatRuntime, AssistantChatTransport } from "@assistant-ui/react-ai-sdk";
import { AssistantRuntimeProvider } from "@assistant-ui/react";
import { AssistantModal } from "@/components/assistant-ui/assistant-modal";

export default function RootPage() {
  const runtime = useChatRuntime({
    transport: new AssistantChatTransport({ api: "/api/chat" }),
  });

  return (
    <div className="relative h-screen w-screen overflow-hidden overflow-x-hidden overflow-y-hidden">
      {/* SQLPage Iframe */}
      <iframe 
        src={process.env.NEXT_PUBLIC_SQLPAGE_BASE_URL} 
        className="size-full border-none m-0 p-0"
        title="Qualityfolio"
      />
      
      {/* Persistent AI Assistant Modal */}
      <AssistantRuntimeProvider runtime={runtime}>
        <AssistantModal />
      </AssistantRuntimeProvider>
    </div>
  );
}
