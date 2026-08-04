import * as React from "react";
export interface SelectOption { value: string; label: string }
/** Native select with brand chrome and a small caret. */
export interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  label?: string; hint?: string; error?: string; required?: boolean;
  options?: (SelectOption | string)[];
  size?: "sm" | "md" | "lg";
}
export declare function Select(props: SelectProps): JSX.Element;
