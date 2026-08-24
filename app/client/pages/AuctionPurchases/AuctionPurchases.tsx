import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import PageLayout from "@/layouts/PageLayout";
import Select from "@/ui/Select";
import { useAuctionPurchases } from "@/api/query/useAuctionPurchases";
import TeamPurchaseCard from "./TeamPurchaseCard";
import PurchaseRankings from "./PurchaseRankings";
import styles from "../AuctionSummary/AuctionSummary.module.scss";

interface IStageOption {
  value: number | null,
  label: string,
}

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
  const [stage, setStage] = useState<number | null>(null);

  const stageOptions: IStageOption[] = useMemo(
    () => [
      { value: null, label: t("auction_purchases.all_stages") },
      ...(data?.stages ?? []).map((number) => ({ value: number, label: t("auction_purchases.stage", { number }) })),
    ],
    [data?.stages, t],
  );

  // filter each team's buys to the chosen stage, recompute the spent total, drop empty teams
  const teams = useMemo(() => {
    if (!data) return [];
    if (stage == null) return data.teams;

    return data.teams
      .map((group) => {
        const bought = group.bought.filter((transfer) => transfer.stage === stage);
        return { ...group, bought, total_spent: bought.reduce((sum, transfer) => sum + transfer.price, 0) };
      })
      .filter((group) => group.bought.length > 0)
      // keep the signed-in user's team on top, the rest by spend (mirrors the server order)
      .sort((a, b) => {
        if (a.team.id === data.current_team_id) return -1;
        if (b.team.id === data.current_team_id) return 1;
        return b.total_spent - a.total_spent;
      });
  }, [data, stage]);

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

          {data && data.stages.length > 1 && (
            <div className={styles.filterBar}>
              <span className={styles.filterLabel}>{t("auction_purchases.stage_filter")}</span>
              <div className={styles.filterSelect}>
                <Select<IStageOption>
                  options={stageOptions}
                  value={stageOptions.find((option) => option.value === stage) ?? null}
                  getOptionValue={(option) => String(option.value)}
                  formatOptionLabel={(option) => option.label}
                  onChange={(option) => setStage((option as IStageOption)?.value ?? null)}
                />
              </div>
            </div>
          )}

          {isLoading || !data ? (
            <div className={styles.loading}>{t("common.loading")}</div>
          ) : (
            <div className={styles.cards}>
              {teams.map((group) => (
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
