import { useTranslation } from "react-i18next";
import PlayerAvatar from "@/components/PlayerAvatar";
import { Row, Section } from "../AuctionSummary/RankingRow";
import { IAuctionPurchases } from "@/interfaces/AuctionPurchases";
import { IAuctionRankingEntry, IAuctionTransfer } from "@/interfaces/AuctionTransfers";
import styles from "../AuctionSummary/AuctionSummary.module.scss";

const PurchaseRankings = ({ purchases }: { purchases: IAuctionPurchases }) => {
  const { t } = useTranslation();

  const teamLogo = (entry: IAuctionRankingEntry) => (
    <img className={styles.rankLogo} src={entry.team.logo_path} alt="" />
  );

  return (
    <aside className={styles.rankings}>
      <Section title={t("auction_purchases.top_spenders")}>
        {purchases.top_spenders.map((entry, i) => (
          <Row
            key={entry.team.id}
            index={i + 1}
            logo={teamLogo(entry)}
            name={entry.team.human_name}
            value={<span className={styles.rankSpent}>−{entry.value}M</span>}
          />
        ))}
      </Section>

      <Section title={t("auction_purchases.top_buy")}>
        {purchases.top_buy.map((transfer: IAuctionTransfer, i) => (
          <Row
            key={transfer.id}
            index={i + 1}
            rowClassName={styles.rankSaleRow}
            logo={
              <PlayerAvatar
                avatarSrc={transfer.player.avatar_path}
                clubKitSrc={transfer.player.kit_path}
                className={styles.rankSaleAvatar}
              />
            }
            name={transfer.player.name}
            value={`${transfer.price}M`}
          />
        ))}
      </Section>
    </aside>
  );
};

export default PurchaseRankings;
