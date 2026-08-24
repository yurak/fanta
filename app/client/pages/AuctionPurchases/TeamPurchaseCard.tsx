import { useTranslation } from "react-i18next";
import PlayerRows from "../AuctionSummary/PlayerRows";
import { IAuctionPurchaseTeamGroup } from "@/interfaces/AuctionPurchases";
import styles from "../AuctionSummary/AuctionSummary.module.scss";

const money = (value: number) => `${value}M`;

const TeamPurchaseCard = ({ group }: { group: IAuctionPurchaseTeamGroup }) => {
  const { t } = useTranslation();

  return (
    <div className={styles.card}>
      <div className={styles.cardHead}>
        <a className={styles.cardTeam} href={`/teams/${group.team.id}`}>
          <img className={styles.cardLogo} src={group.team.logo_path} alt="" />
          <span className={styles.cardName}>{group.team.human_name}</span>
        </a>
        <div className={styles.cardSpent}>−{money(group.total_spent)}</div>
      </div>

      <div className={styles.cardTotalRow}>
        <span>{t("auction_purchases.bought")} ({group.bought.length})</span>
        <span>{money(group.total_spent)}</span>
      </div>

      <PlayerRows transfers={group.bought} />
    </div>
  );
};

export default TeamPurchaseCard;
