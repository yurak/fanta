import { ReactNode } from "react";
import cn from "classnames";
import SortDownIcon from "@/assets/icons/sortDown.svg";
import TableCell from "../TableCell";
import styles from "./TableHeaderCell.module.scss";

const TableHeaderCell = ({
  className,
  ellipsis,
  onSort,
  withSort,
  isSorter,
  title,
}: {
  className?: string,
  onSort: () => void,
  withSort: boolean,
  isSorter: boolean,
  ellipsis?: boolean,
  title?: ReactNode,
}) => {
  return (
    <TableCell
      className={cn(styles.headerColumn, className, {
        [styles.isSorter]: isSorter,
        [styles.withoutTitle]: !title,
        [styles.withSort]: withSort,
      })}
      innerClassName={cn(styles.headerColumnInner, {
        [styles.withSortInner]: withSort,
        [styles.headerEllipsis]: ellipsis,
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
