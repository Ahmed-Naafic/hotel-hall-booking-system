import * as React from "react";
/** Small uppercase status label. Square-ish corners — use Tag for pill shapes. */
export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  children?: React.ReactNode;
  tone?: "navy" | "teal" | "gold" | "success" | "warning" | "danger" | "neutral" | "solid";
  size?: "sm" | "md";
}
export declare function Badge(props: BadgeProps): JSX.Element;
