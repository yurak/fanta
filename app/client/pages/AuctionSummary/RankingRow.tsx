import { ReactNode, useState } from "react";
import cn from "classnames";
import styles from "./AuctionSummary.module.scss";

export const Section = ({ title, children }: { title: string, children: ReactNode }) => {
  const [open, setOpen] = useState(true);

  return (
    <div className={styles.rankSection}>
      <button type="button" className={styles.rankHead} onClick={() => setOpen((v) => !v)}>
        <span>{title}</span>
        <span className={cn(styles.rankChevron, { [styles.rankChevronClosed]: !open })}>⌃</span>
      </button>
      {open && <div className={styles.rankList}>{children}</div>}
    </div>
  );
};

export const Row = ({
  index,
  logo,
  name,
  value,
  rowClassName,
}: {
  index: number,
  logo: ReactNode,
  name: string,
  value: ReactNode,
  rowClassName?: string,
}) => (
  <div className={cn(styles.rankRow, rowClassName)}>
    <span className={styles.rankIndex}>{index}</span>
    {logo}
    <span className={styles.rankName}>{name}</span>
    <span className={styles.rankValue}>{value}</span>
  </div>
);
