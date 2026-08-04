import * as React from "react";
/** Pill-shaped filter/amenity chip. Selected state is a teal 1.5px border + teal-100 fill. */
export interface TagProps extends React.HTMLAttributes<HTMLSpanElement> {
  children?: React.ReactNode;
  icon?: React.ReactNode;
  selected?: boolean;
  onRemove?: (e: React.MouseEvent) => void;
  onClick?: (e: React.MouseEvent) => void;
}
export declare function Tag(props: TagProps): JSX.Element;
