"use client";

import { BotIcon, XIcon, SparklesIcon } from "lucide-react";
import { forwardRef } from "react";
import { AssistantModalPrimitive } from "@assistant-ui/react";
import { Thread } from "@/components/assistant-ui/thread";
import { TooltipIconButton } from "@/components/assistant-ui/tooltip-icon-button";

const AssistantModal = () => {
  return (
    <AssistantModalPrimitive.Root>
      <AssistantModalPrimitive.Anchor className="fixed bottom-4 right-4 z-50">
        <AssistantModalTrigger />
      </AssistantModalPrimitive.Anchor>
      <AssistantModalPrimitive.Content
        sideOffset={16}
        className="z-50 h-[700px] w-[400px] overflow-hidden rounded-2xl border border-border bg-background shadow-2xl data-[state=closed]:animate-out data-[state=open]:animate-in data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 flex flex-col"
      >
        <AssistantModalHeader />
        <Thread />
      </AssistantModalPrimitive.Content>
    </AssistantModalPrimitive.Root>
  );
};

const AssistantModalHeader = () => {
  return (
    <div className="flex items-center gap-3 p-4 border-b border-border/50 bg-background/50 backdrop-blur-md sticky top-0 z-10 shrink-0">
      <div className="size-11 rounded-xl overflow-hidden shadow-xl shadow-primary/10 border border-border/50 bg-white p-1">
        <img 
          src="https://qualityfolio.dev/favicon.png" 
          alt="Qualityfolio Logo" 
          className="size-full object-contain scale-125"
        />
      </div>
      <div className="flex flex-col">
        <h3 className="text-[15px] font-bold tracking-tight text-foreground leading-tight">Qualityfolio AI</h3>
        <div className="flex items-center gap-1.5 pt-0.5">
          <div className="relative flex size-1.5">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full size-1.5 bg-green-500"></span>
          </div>
          <span className="text-[11px] text-muted-foreground/90 font-semibold tracking-wide uppercase">active</span>
        </div>
      </div>
      <div className="ml-auto">
        <AssistantModalPrimitive.Trigger asChild>
          <TooltipIconButton tooltip="Close" variant="ghost" className="size-9 rounded-xl text-muted-foreground hover:text-foreground">
             <XIcon className="size-4" />
          </TooltipIconButton>
        </AssistantModalPrimitive.Trigger>
      </div>
    </div>
  )
}

const AssistantModalTrigger = forwardRef<
  HTMLButtonElement,
  Record<string, never>
>((props, ref) => {
  return (
    <AssistantModalPrimitive.Trigger asChild>
      <TooltipIconButton
        {...props}
        variant="default"
        tooltip="Open Assistant"
        ref={ref}
        className="size-14 rounded-full shadow-lg bg-gradient-to-br from-[#2f10a0] to-[#7c3aed] hover:shadow-xl transition-all overflow-hidden p-0 flex items-center justify-center"
      >
        <svg 
          width="26" 
          height="26" 
          viewBox="0 0 24 24" 
          fill="none" 
          stroke="white" 
          strokeWidth="2" 
          strokeLinecap="round" 
          strokeLinejoin="round"
        >
          <path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>
          <path d="M8 12h.01"/>
          <path d="M12 12h.01"/>
          <path d="M16 12h.01"/>
        </svg>
      </TooltipIconButton>
    </AssistantModalPrimitive.Trigger>
  );
});

AssistantModalTrigger.displayName = "AssistantModalTrigger";

export { AssistantModal };
