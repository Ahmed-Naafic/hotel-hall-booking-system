import * as React from "react";
export interface TabItem { id: string; label: string; count?: number }
/** Section switcher. `underline` for page-level, `segmented` for in-card. */
export interface TabsProps extends React.HTMLAttributes<HTMLDivElement> {
  items: TabItem[];
  value?: string;
  onChange?: (id: string) => void;
  variant?: "underline" | "segmented";
}
export declare function Tabs(props: TabsProps): JSX.Element;
