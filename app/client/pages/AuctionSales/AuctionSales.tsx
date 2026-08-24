import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import PageLayout from "@/layouts/PageLayout";
import { useAuctionSales } from "@/api/query/useAuctionSales";
import TeamDropCard from "./TeamDropCard";
import SalesRankings from "./SalesRankings";
import styles from "../AuctionSummary/AuctionSummary.module.scss";

const formatDate = (iso: string | null) => {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
};

const AuctionSales = () => {
  const params = useParams<{ leagueId: string, auctionId: string }>();
  const leagueId = Number(params.leagueId);
  const auctionId = Number(params.auctionId);
  const { data, isLoading } = useAuctionSales(leagueId, auctionId);
  const { t } = useTranslation();

  return (
    <PageLayout withSidebar>
      <div className={styles.layout}>
        <div className={styles.main}>
          <a className={styles.header} href={`/leagues/${leagueId}/auctions`}>
            <span className={styles.back}>←</span>
            <span className={styles.title}>{t("auction_sales.title", { number: data?.auction.number ?? "" })}</span>
          </a>

          <div className={styles.phaseBanner}>
            <span className={styles.phaseName}>{t("auction_sales.phase")}</span>
            {data?.auction.deadline && (
              <span className={styles.phaseStatus}>
                🏁 {t("auction_sales.finished")}: {formatDate(data.auction.deadline)}
              </span>
            )}
          </div>

          {isLoading || !data ? (
            <div className={styles.loading}>{t("common.loading")}</div>
          ) : (
            <div className={styles.cards}>
              {data.teams.map((group) => (
                <TeamDropCard key={group.team.id} group={group} />
              ))}
            </div>
          )}
        </div>

        {data && <SalesRankings sales={data} />}
      </div>
    </PageLayout>
  );
};

export default AuctionSales;
