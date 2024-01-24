import { ReactNode } from "react";
import cn from "classnames";
import styles from "./TableCell.module.scss";

const TableCell = ({
  children,
  className,
  innerClassName,
  onClick,
}: {
  children: ReactNode,
  className?: string,
  innerClassName?: string,
  onClick?: () => void,
}) => {
  return (
    <div className={cn(styles.column, className)} onClick={onClick}>
      <div className={cn(styles.columnInner, innerClassName)}>{children}</div>
    </div>
  );
};

export default TableCell;
