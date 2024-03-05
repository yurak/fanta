import { ReactNode } from "react";
import cn from "classnames";
import SortDownIcon from "@/assets/icons/sortDown.svg";
import TableCell from "../TableCell";
import { SortOrder } from "../interfaces";
import styles from "./TableHeaderCell.module.scss";

const TableHeaderCell = ({
  className,
  ellipsis,
  onSort,
  withSort,
  isSorter,
  sortOrder,
  title,
}: {
  className?: string,
  onSort: () => void,
  withSort: boolean,
  isSorter: boolean,
  sortOrder?: SortOrder | null,
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
      {withSort && (
        <SortDownIcon
          className={cn(styles.sortIcon, {
            [styles.reverseIcon]: sortOrder === "asc",
          })}
        />
      )}
    </TableCell>
  );
};

export default TableHeaderCell;
