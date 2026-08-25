import { useState } from "react";
import { useTranslation } from "react-i18next";
import cn from "classnames";
import PlayerRows from "../AuctionSummary/PlayerRows";
import { IAuctionSaleTeamGroup } from "@/interfaces/AuctionSales";
import styles from "../AuctionSummary/AuctionSummary.module.scss";

type TabId = "dropped" | "left";

const money = (value: number) => `${value}M`;

const TeamDropCard = ({ group }: { group: IAuctionSaleTeamGroup }) => {
  const { t } = useTranslation();
  const [active, setActive] = useState<TabId>(group.dropped.length ? "dropped" : "left");

  const rows = active === "dropped" ? group.dropped : group.left;
  const total = rows.reduce((sum, transfer) => sum + transfer.price, 0);

  const tab = (id: TabId, label: string, count: number) => (
    <button
      type="button"
      className={cn(styles.tab, { [styles.tabActive]: active === id })}
      onClick={(e) => {
        setActive(id);
        e.currentTarget.blur();
      }}
    >
      {label} ({count})
    </button>
  );

  return (
    <div className={styles.card}>
      <div className={styles.cardHead}>
        <a className={styles.cardTeam} href={`/teams/${group.team.id}`}>
          <img className={styles.cardLogo} src={group.team.logo_path} alt="" />
          <span className={styles.cardName}>{group.team.human_name}</span>
        </a>
        <div className={styles.cardIncome}>+{money(group.net_income)}</div>
      </div>

      <div className={styles.tabs}>
        {tab("dropped", t("auction_sales.dropped"), group.dropped.length)}
        {tab("left", t("auction_sales.left"), group.left.length)}
      </div>

      <div className={styles.cardTotalRow}>
        <span>{t("auction_sales.total")}</span>
        <span>{money(total)}</span>
      </div>

      <PlayerRows key={active} transfers={rows} />
    </div>
  );
};

export default TeamDropCard;
