import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import PageLayout from "@/layouts/PageLayout";
import { useAuctionPurchases } from "@/api/query/useAuctionPurchases";
import TeamPurchaseCard from "./TeamPurchaseCard";
import PurchaseRankings from "./PurchaseRankings";
import styles from "../AuctionSummary/AuctionSummary.module.scss";

const formatDate = (iso: string | null) => {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
};

const AuctionPurchases = () => {
  const params = useParams<{ leagueId: string, auctionId: string }>();
  const leagueId = Number(params.leagueId);
  const auctionId = Number(params.auctionId);
  const { data, isLoading } = useAuctionPurchases(leagueId, auctionId);
  const { t } = useTranslation();

  return (
    <PageLayout withSidebar>
      <div className={styles.layout}>
        <div className={styles.main}>
          <a className={styles.header} href={`/leagues/${leagueId}/auctions`}>
            <span className={styles.back}>←</span>
            <span className={styles.title}>{t("auction_purchases.title", { number: data?.auction.number ?? "" })}</span>
          </a>

          <div className={styles.phaseBanner}>
            <span className={styles.phaseName}>{t("auction_purchases.phase")}</span>
            {data?.auction.deadline && (
              <span className={styles.phaseStatus}>
                🏁 {t("auction_purchases.finished")}: {formatDate(data.auction.deadline)}
              </span>
            )}
          </div>

          {isLoading || !data ? (
            <div className={styles.loading}>{t("common.loading")}</div>
          ) : (
            <div className={styles.cards}>
              {data.teams.map((group) => (
                <TeamPurchaseCard key={group.team.id} group={group} />
              ))}
            </div>
          )}
        </div>

        {data && <PurchaseRankings purchases={data} />}
      </div>
    </PageLayout>
  );
};

export default AuctionPurchases;
