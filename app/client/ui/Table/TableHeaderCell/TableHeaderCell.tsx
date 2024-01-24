import { ReactNode } from "react";
import cn from "classnames";
import SortDownIcon from "../../../assets/icons/sortDown.svg";
import styles from "./TableHeaderCell.module.scss";
import TableCell from "../TableCell";

const TableHeaderCell = ({
  className,
  onSort,
  withSort,
  isSorter,
  title,
}: {
  className?: string,
  onSort: () => void,
  withSort: boolean,
  isSorter: boolean,
  title?: ReactNode,
}) => {
  return (
    <TableCell
      className={cn(styles.headerColumn, className, {
        [styles.isSorter]: isSorter,
        [styles.withoutTitle]: !title,
        [styles.withSort]: withSort,
      })}
      onClick={() => {
        if (withSort) {
          onSort();
        }
      }}
    >
      {title}
      {withSort && <SortDownIcon className={cn(styles.sortIcon)} />}
    </TableCell>
  );
};

export default TableHeaderCell;
