import * as React from "react";
/** Square icon-only control. `glass` is for use over photography only. */
export interface IconButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  icon: React.ReactNode;
  /** Required accessible name. */
  label: string;
  variant?: "ghost" | "outline" | "solid" | "glass";
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
  round?: boolean;
}
export declare function IconButton(props: IconButtonProps): JSX.Element;
