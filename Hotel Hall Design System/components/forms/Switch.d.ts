import * as React from "react";
/** Instant-apply toggle (housekeeping, notifications). Not for form submission. */
export interface SwitchProps {
  label?: React.ReactNode; checked?: boolean; defaultChecked?: boolean;
  onChange?: (next: boolean) => void; disabled?: boolean; style?: React.CSSProperties;
}
export declare function Switch(props: SwitchProps): JSX.Element;
