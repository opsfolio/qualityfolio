"use client";

import { type FC } from "react";
import { SUGGESTIONS } from "@/lib/suggestions";
import { cn } from "@/lib/utils";
import {
  ActionBarPrimitive,
  ComposerPrimitive,
  MessagePrimitive,
  MessagePartPrimitive,
  ThreadPrimitive,
  useAssistantRuntime,
  useAuiState,
  AttachmentPrimitive,
  ActionBarMorePrimitive,
  SuggestionPrimitive,
} from "@assistant-ui/react";
import { MarkdownTextPrimitive } from "@assistant-ui/react-markdown";
import remarkGfm from "remark-gfm";
import {
  ArrowDownIcon,
  CheckIcon,
  CopyIcon,
  Edit2Icon,
  RotateCcwIcon,
  SendHorizontalIcon,
  StopCircleIcon,
  AlertCircleIcon,
  SparklesIcon,
  MoreHorizontalIcon,
  PlusIcon,
  ArrowUpIcon,
  XIcon,
  DownloadIcon,
} from "lucide-react";
import { TooltipIconButton } from "@/components/assistant-ui/tooltip-icon-button";
import { Button } from "@/components/ui/button";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";

const MarkdownText: FC<any> = () => {
  return (
    <MarkdownTextPrimitive
      remarkPlugins={[remarkGfm]}
      className="prose prose-sm max-w-none text-inherit"
      components={{
        table: ({ children }) => (
          <div className="my-4 w-full overflow-x-auto rounded-lg border border-muted-foreground/20 shadow-sm">
            <table className="aui-md-table w-full border-separate border-spacing-0">
              {children}
            </table>
          </div>
        ),
        th: ({ children }) => (
          <th className="aui-md-th bg-muted px-2 py-1.5 text-left font-semibold text-xs uppercase first:rounded-tl-lg last:rounded-tr-lg border-b border-muted-foreground/20">
            {children}
          </th>
        ),
        td: ({ children }) => (
          <td className="aui-md-td border-muted-foreground/20 border-b border-l px-2 py-1.5 text-left text-sm last:border-r">
            {children}
          </td>
        ),
        tr: ({ children }) => (
          <tr className="aui-md-tr m-0 border-b p-0 first:border-t [&:last-child>td:first-child]:rounded-bl-lg [&:last-child>td:last-child]:rounded-br-lg">
            {children}
          </tr>
        ),
      }}
    />
  );
};

const Thread: FC = () => {
  return (
    <ThreadPrimitive.Root className="flex h-full flex-col bg-transparent">
      <ThreadPrimitive.Viewport className="flex flex-1 flex-col overflow-y-auto scroll-smooth px-6 pt-6">
        <ThreadPrimitive.Empty>
          <ThreadWelcome />
        </ThreadPrimitive.Empty>
        <ThreadPrimitive.Messages
          components={{
            UserMessage,
            EditComposer,
            AssistantMessage,
          }}
        />
        <div className="min-h-12 flex-grow" />
      </ThreadPrimitive.Viewport>

      <div className="sticky bottom-0 mt-4 flex w-full flex-col items-center justify-end pb-8 px-4 bg-transparent backdrop-blur-none">
        <ThreadScrollToBottom />
        <Composer />
      </div>
    </ThreadPrimitive.Root>
  );
};

const SuggestionCard: FC<{ suggestion: any }> = ({ suggestion }) => {
  return (
    <ThreadPrimitive.Suggestion
      prompt={suggestion.prompt}
      asChild
    >
      <button className="flex flex-col gap-1 rounded-2xl border border-border/40 bg-background/30 p-4 text-left transition-all hover:bg-muted/50 focus:outline-none focus:ring-2 focus:ring-primary/20 group">
        <span className="text-sm font-semibold tracking-tight group-hover:text-primary transition-colors">
          {suggestion.title}
        </span>
        {suggestion.description && (
          <span className="text-[11px] text-muted-foreground line-clamp-2 leading-relaxed opacity-80 group-hover:opacity-100 transition-opacity">
            {suggestion.description}
          </span>
        )}
      </button>
    </ThreadPrimitive.Suggestion>
  );
};

const ThreadWelcome: FC = () => {
  return (
    <div className="flex flex-col items-center justify-center py-8 px-6 text-center max-w-2xl mx-auto">
      <h2 className="text-2xl font-bold tracking-tight mb-3">
        How can I help you today?
      </h2>
      <p className="text-muted-foreground text-base mb-10 max-w-md mx-auto leading-relaxed opacity-80">
        I can assist with test cases, defects, cycles, or assignees. Ask me anything!
      </p>

      <div className="grid w-full grid-cols-1 gap-3 max-w-2xl">
        {SUGGESTIONS.map((suggestion, idx) => (
          <SuggestionCard key={idx} suggestion={suggestion} />
        ))}
      </div>
    </div>
  );
};

const ThreadScrollToBottom: FC = () => {
  return (
    <ThreadPrimitive.ScrollToBottom asChild>
      <TooltipIconButton
        tooltip="Scroll to bottom"
        variant="outline"
        className="absolute -top-8 rounded-full disabled:invisible"
      >
        <ArrowDownIcon />
      </TooltipIconButton>
    </ThreadPrimitive.ScrollToBottom>
  );
};

const ComposerAttachments: FC = () => {
  return (
    <div className="flex flex-wrap gap-2 px-6 pt-3">
      <ComposerPrimitive.Attachments>
        {(attachment: any) => (
          <AttachmentPrimitive.Root
            key={attachment.attachment.id}
            className="flex items-center gap-2 rounded-xl border border-border/40 bg-muted/30 px-3 py-1.5 text-[11px] font-medium shadow-sm transition-all hover:border-border/60"
          >
            <div className="max-w-[150px] truncate">
              <AttachmentPrimitive.Name />
            </div>
            <AttachmentPrimitive.Remove asChild>
              <button className="text-muted-foreground/60 hover:text-destructive transition-colors ml-1">
                <XIcon className="size-3.5" />
              </button>
            </AttachmentPrimitive.Remove>
          </AttachmentPrimitive.Root>
        )}
      </ComposerPrimitive.Attachments>
    </div>
  );
};

const Composer: FC = () => {
  return (
    <ComposerPrimitive.Root className="flex w-full max-w-2xl mx-auto flex-col rounded-[32px] border border-border/60 bg-background transition-all duration-300 ease-out focus-within:border-primary/40 focus-within:shadow-[0_8px_30px_rgba(0,0,0,0.04)]">
      <ComposerAttachments />
      <ComposerPrimitive.Input
        autoFocus
        placeholder="Send a message..."
        rows={1}
        className="placeholder:text-muted-foreground/60 max-h-40 w-full resize-none border-none bg-transparent px-6 pt-5 pb-2 text-[15px] outline-none focus:ring-0 disabled:cursor-not-allowed selection:bg-primary/20"
      />
      <div className="flex items-center justify-between px-4 pb-4">
        <div className="flex items-center">
          <ComposerPrimitive.AddAttachment asChild>
            <TooltipIconButton
              tooltip="Attach"
              variant="ghost"
              className="size-10 rounded-full text-muted-foreground hover:bg-muted"
            >
              <PlusIcon className="size-5" strokeWidth={2.5} />
            </TooltipIconButton>
          </ComposerPrimitive.AddAttachment>
        </div>
        <div className="flex items-center gap-2">
          <ThreadPrimitive.If running={false}>
            <ComposerPrimitive.Send asChild>
              <TooltipIconButton
                tooltip="Send"
                variant="default"
                className="size-10 rounded-full bg-primary/95 hover:bg-primary shadow-sm active:scale-95 transition-all duration-200 p-0"
              >
                <ArrowUpIcon className="size-5 text-primary-foreground" strokeWidth={3} />
              </TooltipIconButton>
            </ComposerPrimitive.Send>
          </ThreadPrimitive.If>
          <ThreadPrimitive.If running>
            <ComposerPrimitive.Cancel asChild>
              <TooltipIconButton
                tooltip="Stop"
                variant="outline"
                className="size-10 rounded-full hover:bg-destructive/10 hover:text-destructive hover:border-destructive/20 transition-all duration-200"
              >
                <StopCircleIcon className="size-5" />
              </TooltipIconButton>
            </ComposerPrimitive.Cancel>
          </ThreadPrimitive.If>
        </div>
      </div>
    </ComposerPrimitive.Root>
  );
};

const MessageAttachments: FC = () => {
  return (
    <div className="flex flex-col gap-2 mt-2">
      <MessagePrimitive.Attachments>
        {(attachment: any) => (
        <AttachmentPrimitive.Root
          key={attachment.id}
          className="flex items-center gap-2 rounded-xl border border-border/40 bg-background/50 px-3 py-2 text-[11px] font-medium transition-all hover:bg-background"
        >
          <div className="max-w-[200px] truncate italic text-muted-foreground">
            <AttachmentPrimitive.Name />
          </div>
        </AttachmentPrimitive.Root>
      )}
    </MessagePrimitive.Attachments>
    </div>
  );
};

const UserMessage: FC = () => {
  return (
    <MessagePrimitive.Root className="grid w-full max-w-2xl auto-rows-auto grid-cols-[1fr_auto] gap-y-1 py-2 group">
      <div className="bg-muted text-foreground max-w-xl break-words rounded-2xl px-4 py-2 col-start-1 text-sm">
        <MessagePrimitive.Content />
        <MessageAttachments />
      </div>
      <UserActionBar />
    </MessagePrimitive.Root>
  );
};

const EditComposerHeader: FC = () => {
  return <div className="col-start-2 row-start-1" />;
};

const UserActionBar: FC = () => {
  return (
    <ActionBarPrimitive.Root
      hideWhenRunning
      autohide="not-last"
      className="flex flex-col items-end col-start-2 row-start-1 opacity-0 group-hover:opacity-100 transition-opacity"
    >
      <Tooltip>
        <TooltipTrigger asChild>
          <ActionBarPrimitive.Edit asChild>
            <Button variant="ghost" className="size-8 rounded-lg p-0 text-muted-foreground hover:text-foreground">
              <Edit2Icon className="size-4" />
              <span className="sr-only">Edit</span>
            </Button>
          </ActionBarPrimitive.Edit>
        </TooltipTrigger>
        <TooltipContent side="bottom">Edit</TooltipContent>
      </Tooltip>
    </ActionBarPrimitive.Root>
  );
};

const EditComposer: FC = () => {
  return (
    <MessagePrimitive.Root className="grid w-full max-w-2xl auto-rows-auto grid-cols-1 gap-y-2 py-2">
      <ComposerPrimitive.Root className="flex w-full flex-col rounded-2xl border bg-muted/20 focus-within:bg-background focus-within:shadow-md transition-all focus-within:border-primary/20">
        <ComposerPrimitive.Input className="flex h-10 w-full resize-none bg-transparent px-4 py-2 text-sm outline-none" />
        <div className="mx-2 mb-2 mt-1 flex items-center justify-end gap-2">
          <ComposerPrimitive.Cancel asChild>
            <Button variant="ghost" size="sm" className="h-8 rounded-xl px-3 text-xs">Cancel</Button>
          </ComposerPrimitive.Cancel>
          <ComposerPrimitive.Send asChild>
            <Button size="sm" className="h-8 rounded-xl px-4 text-xs">Send</Button>
          </ComposerPrimitive.Send>
        </div>
      </ComposerPrimitive.Root>
    </MessagePrimitive.Root>
  );
};

const AssistantMessageLoading: FC = () => {
  const isRunning = useAuiState((s) => s.message.status?.type === "running");
  if (!isRunning) return null;
  return (
    <div className="flex items-center gap-2 py-1">
      <div className="flex items-center gap-1">
        <span
          className="inline-block size-1 rounded-full bg-muted-foreground animate-pulse"
          style={{ animationDelay: "0ms", animationDuration: "1s" }}
        />
        <span
          className="inline-block size-1 rounded-full bg-muted-foreground animate-pulse"
          style={{ animationDelay: "200ms", animationDuration: "1s" }}
        />
        <span
          className="inline-block size-1 rounded-full bg-muted-foreground animate-pulse"
          style={{ animationDelay: "400ms", animationDuration: "1s" }}
        />
      </div>
      <span className="text-xs text-muted-foreground leading-none">thinking...</span>
    </div>
  );
};

const AssistantMessage: FC = () => {
  return (
    <MessagePrimitive.Root className="relative flex w-full max-w-2xl flex-col py-2 group">
      <div className="text-foreground max-w-xl break-words text-sm leading-relaxed">
        <MessagePrimitive.Content
          components={{
            Text: MarkdownText,
          }}
        />
        <MessageAttachments />
        <AssistantMessageLoading />
        <MessagePrimitive.Error>
          <AssistantMessageError />
        </MessagePrimitive.Error>
      </div>
      <AssistantActionBar />
    </MessagePrimitive.Root>
  );
};

const AssistantMessageError: FC = () => {
  return (
    <div className="flex items-start gap-2 mt-2 rounded-xl border border-destructive/40 bg-destructive/10 px-3 py-2.5 text-sm text-destructive">
      <AlertCircleIcon className="size-4 mt-0.5 shrink-0" />
      <span>Something went wrong. The AI failed to respond — please try again.</span>
    </div>
  );
};

const AssistantActionBar: FC = () => {
  return (
    <ActionBarPrimitive.Root
      hideWhenRunning
      autohide="not-last"
      className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity -ml-1 mt-1 text-muted-foreground"
    >
      <ActionBarPrimitive.Copy asChild>
        <TooltipIconButton
          tooltip="Copy"
          variant="ghost"
          className="size-6 p-1"
        >
          <MessagePrimitive.If copied>
            <CheckIcon />
          </MessagePrimitive.If>
          <MessagePrimitive.If copied={false}>
            <CopyIcon />
          </MessagePrimitive.If>
        </TooltipIconButton>
      </ActionBarPrimitive.Copy>

      <ActionBarPrimitive.Reload asChild>
        <TooltipIconButton
          tooltip="Refresh"
          variant="ghost"
          className="size-6 p-1"
        >
          <RotateCcwIcon />
        </TooltipIconButton>
      </ActionBarPrimitive.Reload>

      <ActionBarMorePrimitive.Root>
        <ActionBarMorePrimitive.Trigger asChild>
          <TooltipIconButton
            tooltip="More"
            variant="ghost"
            className="size-6 p-1"
          >
            <MoreHorizontalIcon />
          </TooltipIconButton>
        </ActionBarMorePrimitive.Trigger>
        <ActionBarMorePrimitive.Content
          align="start"
          className="z-50 min-w-[120px] overflow-hidden rounded-xl border border-border/40 bg-background/95 backdrop-blur-md p-1.5 text-foreground shadow-lg animate-in fade-in-0 zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=top]:slide-in-from-bottom-2"
        >
          <ActionBarPrimitive.ExportMarkdown asChild>
            <ActionBarMorePrimitive.Item className="flex cursor-pointer select-none items-center gap-2 rounded-lg px-2.5 py-2 text-xs font-medium outline-none transition-colors hover:bg-muted hover:text-foreground focus:bg-muted">
              <DownloadIcon className="size-3.5" />
              Export as Markdown
            </ActionBarMorePrimitive.Item>
          </ActionBarPrimitive.ExportMarkdown>
        </ActionBarMorePrimitive.Content>
      </ActionBarMorePrimitive.Root>
    </ActionBarPrimitive.Root>
  );
};

export { Thread };
