import * as React from "react";
/** Navy tooltip on hover/focus. Labels only — never long-form help. */
export interface TooltipProps extends React.HTMLAttributes<HTMLSpanElement> {
  children?: React.ReactNode;
  label: string;
  placement?: "top" | "bottom" | "left" | "right";
}
export declare function Tooltip(props: TooltipProps): JSX.Element;
