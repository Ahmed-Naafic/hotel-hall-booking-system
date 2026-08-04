import * as React from "react";
/**
 * White surface, 10px radius, hairline border, sm shadow. Never a coloured
 * left border. `arch` applies the brand archway radius; `featured` inverts to navy.
 */
export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children?: React.ReactNode;
  /** Image src rendered flush at the top, clipped to the card radius (4:3). */
  image?: string;
  imageAlt?: string;
  arch?: boolean;
  featured?: boolean;
  /** Enables hover lift + shadow step and pointer cursor. */
  interactive?: boolean;
  padding?: string;
}
export declare function Card(props: CardProps): JSX.Element;
export declare function CardTitle(props: React.HTMLAttributes<HTMLDivElement>): JSX.Element;
export declare function CardMeta(props: React.HTMLAttributes<HTMLDivElement>): JSX.Element;
