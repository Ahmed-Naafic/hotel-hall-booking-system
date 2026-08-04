import * as React from "react";
/** Text input with uppercase label, hint and error slots. Focus is a teal ring. */
export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  hint?: string;
  error?: string;
  required?: boolean;
  size?: "sm" | "md" | "lg";
  iconLeft?: React.ReactNode;
  iconRight?: React.ReactNode;
  wrapperStyle?: React.CSSProperties;
}
export declare function Input(props: InputProps): JSX.Element;
/** Label + hint/error wrapper, reusable around any control. */
export interface FieldProps {
  label?: string; hint?: string; error?: string; required?: boolean;
  htmlFor?: string; children?: React.ReactNode; style?: React.CSSProperties;
}
export declare function Field(props: FieldProps): JSX.Element;
