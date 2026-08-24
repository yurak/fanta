import { useTranslation } from "react-i18next";
import PlayerAvatar from "@/components/PlayerAvatar";
import { Row, Section } from "../AuctionSummary/RankingRow";
import { IAuctionSales } from "@/interfaces/AuctionSales";
import { IAuctionRankingEntry, IAuctionTransfer } from "@/interfaces/AuctionTransfers";
import styles from "../AuctionSummary/AuctionSummary.module.scss";

const SalesRankings = ({ sales }: { sales: IAuctionSales }) => {
  const { t } = useTranslation();

  const teamLogo = (entry: IAuctionRankingEntry) => (
    <img className={styles.rankLogo} src={entry.team.logo_path} alt="" />
  );

  return (
    <aside className={styles.rankings}>
      <Section title={t("auction_sales.top_earners")}>
        {sales.top_earners.map((entry, i) => (
          <Row
            key={entry.team.id}
            index={i + 1}
            logo={teamLogo(entry)}
            name={entry.team.human_name}
            value={<span className={styles.rankIncome}>+{entry.value}M</span>}
          />
        ))}
      </Section>

      <Section title={t("auction_sales.top_droppers")}>
        {sales.top_droppers.map((entry, i) => (
          <Row key={entry.team.id} index={i + 1} logo={teamLogo(entry)} name={entry.team.human_name} value={entry.value} />
        ))}
      </Section>

      <Section title={t("auction_sales.top_sale")}>
        {sales.top_sale.map((transfer: IAuctionTransfer, i) => (
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

export default SalesRankings;
