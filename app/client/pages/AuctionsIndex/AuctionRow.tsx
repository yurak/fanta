import cn from "classnames";
import { IAuctionRow } from "@/interfaces/Auctions";
import styles from "./AuctionsIndex.module.scss";

const STATUS_BG: Record<string, string | undefined> = {
  completed: styles.statusCompleted,
  ongoing: styles.statusOngoing,
  coming_soon: styles.statusComingSoon,
};

// `showIcon` puts the emoji into the title (mobile only); desktop keeps the left circle.
const AuctionRow = ({ row, showIcon }: { row: IAuctionRow, showIcon?: boolean }) => (
  <a href={row.href}>
    <div className={styles.row}>
      <div className={cn(styles.iconWrapper, { [styles.iconWrapperActive]: row.icon_active })}>
        <div className={styles.icon}>{row.icon}</div>
      </div>
      <div className={cn(styles.item, { [styles.itemClosed]: row.item_status === "closed" })}>
        <div className={cn(styles.itemTitle, { [styles.droppingTitleCompleted]: row.title_status === "completed" })}>
          {showIcon && <span className={styles.titleIcon}>{row.icon}</span>}
          {row.title}
        </div>
        <div className={cn(styles.transfers, { [styles.transfersOngoing]: row.transfers_status === "ongoing" })}>
          {row.transfers}
        </div>
        <div className={styles.statusCell}>
          <div className={cn(styles.status, STATUS_BG[row.status])}>
            <span className={styles.statusIcon}>
              <img src={row.status_icon} alt="" />
            </span>
            <span>{row.status_text}</span>
          </div>
        </div>
        <div className={styles.date}>{row.date}</div>
        <div className={styles.arrow}>
          <img src={row.arrow_icon} alt="" />
        </div>
      </div>
    </div>
  </a>
);

export default AuctionRow;
