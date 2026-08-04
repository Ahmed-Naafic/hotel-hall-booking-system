import * as React from "react";
/** Gold star rating with optional numeric value and review count. Supports halves. */
export interface RatingProps extends React.HTMLAttributes<HTMLSpanElement> {
  value?: number;
  max?: number;
  size?: number;
  count?: number;
  /** Pass false to hide the numeric value. */
  label?: false | string;
}
export declare function Rating(props: RatingProps): JSX.Element;
