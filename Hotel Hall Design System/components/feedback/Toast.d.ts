import * as React from "react";
/** Navy notification with a 3px tone accent. Factual copy plus one next step. */
export interface ToastProps extends React.HTMLAttributes<HTMLDivElement> {
  title?: string;
  message?: string;
  tone?: "info" | "success" | "warning" | "danger";
  action?: React.ReactNode;
  onDismiss?: () => void;
}
export declare function Toast(props: ToastProps): JSX.Element;
