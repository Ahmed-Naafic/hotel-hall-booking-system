import * as React from "react";
/** Centred modal over a 62% navy overlay. Absolute-positioned within its container. */
export interface DialogProps extends React.HTMLAttributes<HTMLDivElement> {
  open?: boolean;
  title?: string;
  /** Gold uppercase overline above the title. */
  eyebrow?: string;
  children?: React.ReactNode;
  footer?: React.ReactNode;
  onClose?: () => void;
  width?: number;
}
export declare function Dialog(props: DialogProps): JSX.Element | null;
