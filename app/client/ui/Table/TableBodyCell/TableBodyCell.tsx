import cn from "classnames";
import TableCell from "../TableCell";
import styles from "./TableBodyCell.module.scss";

const TableBodyCell = ({
  children,
  align,
  noWrap,
  className,
  withBorder,
}: {
  children: React.ReactNode,
  className: string,
  align?: "right" | "left" | "center",
  noWrap?: boolean,
  withBorder?: boolean,
}) => {
  return (
    <TableCell
      className={cn(styles.dataColumn, className, {
        [styles.right]: align === "right",
        [styles.center]: align === "center",
        [styles.noWrap]: noWrap,
        [styles.withBorder]: withBorder,
      })}
    >
      {children}
    </TableCell>
  );
};

export default TableBodyCell;
