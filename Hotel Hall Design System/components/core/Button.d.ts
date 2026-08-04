import * as React from "react";
/**
 * Primary action control. Uppercase, wide-tracked label; navy by default,
 * teal for accents, gold for celebration/event CTAs.
 */
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children?: React.ReactNode;
  /** navy | teal | gold | outlined | text | white-on-photo */
  variant?: "primary" | "accent" | "gold" | "secondary" | "ghost" | "inverse";
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
  /** Swaps the label for a 3-dot pulse; width is preserved. */
  loading?: boolean;
  fullWidth?: boolean;
  iconLeft?: React.ReactNode;
  iconRight?: React.ReactNode;
  /** Render as another element, e.g. "a". */
  as?: keyof JSX.IntrinsicElements;
}
export declare function Button(props: ButtonProps): JSX.Element;
