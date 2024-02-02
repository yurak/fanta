import cn from "classnames";
import TableCell from "../TableCell";
import styles from "./TableBodyCell.module.scss";

const TableBodyCell = ({
  children,
  align,
  noWrap,
  className,
}: {
  children: React.ReactNode,
  className: string,
  align?: "right" | "left" | "center",
  noWrap?: boolean,
}) => {
  return (
    <TableCell
      className={cn(styles.dataColumn, className, {
        [styles.right]: align === "right",
        [styles.center]: align === "center",
        [styles.noWrap]: noWrap,
      })}
    >
      {children}
    </TableCell>
  );
};

export default TableBodyCell;
