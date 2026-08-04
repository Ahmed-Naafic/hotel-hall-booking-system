import * as React from "react";
/**
 * Check-in / check-out pair with an optional nights readout. Cosmetic —
 * opens a real calendar in production. The site's primary interaction.
 */
export interface DateFieldProps extends React.HTMLAttributes<HTMLDivElement> {
  label?: string;
  checkIn?: string;
  checkOut?: string;
  nights?: number;
  size?: "md" | "lg";
  onClick?: (e: React.MouseEvent) => void;
}
export declare function DateField(props: DateFieldProps): JSX.Element;
