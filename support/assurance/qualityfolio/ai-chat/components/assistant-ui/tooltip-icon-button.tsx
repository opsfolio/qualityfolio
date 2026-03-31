"use client";

import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { Button } from "@/components/ui/button";
import { forwardRef } from "react";
import { cn } from "@/lib/utils";

type TooltipIconButtonProps = React.ComponentPropsWithoutRef<typeof Button> & {
  tooltip: string;
  side?: "top" | "bottom" | "left" | "right";
  asChild?: boolean;
};

const TooltipIconButton = forwardRef<HTMLButtonElement, TooltipIconButtonProps>(
  ({ children, tooltip, className, side = "bottom", asChild, ...props }, ref) => {
    return (
      <Tooltip>
        <TooltipTrigger asChild={asChild}>
          <Button
            {...props}
            ref={ref}
            asChild={asChild}
            className={cn("size-9 p-0", className)}
          >
            {children}
            <span className="sr-only">{tooltip}</span>
          </Button>
        </TooltipTrigger>
        <TooltipContent side={side}>{tooltip}</TooltipContent>
      </Tooltip>
    );
  }
);

TooltipIconButton.displayName = "TooltipIconButton";

export { TooltipIconButton };
