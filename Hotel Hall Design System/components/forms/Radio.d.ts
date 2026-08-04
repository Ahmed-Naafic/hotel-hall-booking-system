import * as React from "react";
/** Single radio. Prefer RadioGroup for sets (rate plans, bed types). */
export interface RadioProps {
  label?: React.ReactNode; description?: string; checked?: boolean;
  name?: string; value?: string; onChange?: (value?: string) => void;
  disabled?: boolean; style?: React.CSSProperties;
}
export declare function Radio(props: RadioProps): JSX.Element;
export interface RadioGroupProps {
  label?: string; name?: string; value?: string;
  options?: { value: string; label: string; description?: string }[];
  onChange?: (value?: string) => void;
  style?: React.CSSProperties;
}
export declare function RadioGroup(props: RadioGroupProps): JSX.Element;
