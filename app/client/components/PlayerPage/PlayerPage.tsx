import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import Skeleton from "react-loading-skeleton";
import EmptyState from "@/ui/EmptyState";
import { Position } from "@/interfaces/Position";
import { usePlayer } from "@/api/query/usePlayer";
import { usePlayerStats } from "@/api/query/usePlayerStats";
import PlayerBanner from "./PlayerBanner";
import PlayerBio from "./PlayerBio";
import PlayerClubTransfers from "./PlayerClubTransfers";
import PlayerPerformance from "./PlayerPerformance";
import PlayerSeasonStats from "./PlayerSeasonStats";
import ArrowLeft from "@/assets/icons/arrow_left.svg";
import styles from "./PlayerPage.module.scss";

const PlayerPage = ({ id }: { id: number }) => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [selectedSeasonId, setSelectedSeasonId] = useState<number | null>(null);
  const { data: player, isLoading, isError } = usePlayer(id);
  const { data: stats } = usePlayerStats(id, selectedSeasonId);

  const seasons = useMemo(() => {
    const map = new Map<number, string>();
    stats?.season_stats.forEach((stat) => {
      if (stat.season) {
        map.set(stat.season.id, `${stat.season.start_year}-${stat.season.end_year}`);
      }
    });

    return [...map].map(([seasonId, label]) => ({ id: seasonId, label })).sort((a, b) => b.id - a.id);
  }, [stats?.season_stats]);

  if (isLoading) {
    return (
      <div className={styles.content}>
        <Skeleton height={328} borderRadius={8} />
        <Skeleton height={320} style={{ marginTop: 16 }} />
      </div>
    );
  }

  if (isError || !player) {
    return <EmptyState title={t("players.not_found")} />;
  }

  const isGoalkeeper = player.position_classic_arr.includes(Position.GK);
  const activeSeasonId = selectedSeasonId ?? seasons[0]?.id ?? null;

  return (
    <div className={styles.content}>
      <div className={styles.links}>
        <div className={styles.backButton} onClick={() => navigate(-1)}>
          <ArrowLeft />
        </div>
      </div>

      <PlayerBanner player={player} />

      <div className={styles.tables}>
        <div>
          <PlayerBio player={player} />
        </div>
        <div>
          {stats ? (
            <PlayerPerformance
              isGoalkeeper={isGoalkeeper}
              nationality={player.nationality}
              seasons={seasons}
              activeSeasonId={activeSeasonId}
              onSeasonChange={setSelectedSeasonId}
              data={{
                domestic: { rounds: stats.round_stats, total: stats.current_season_stat },
                eurocups: {
                  rounds: stats.round_stats_eurocup,
                  total: stats.current_season_stat_eurocup,
                },
                international: {
                  rounds: stats.round_stats_national,
                  total: stats.current_season_stat_national,
                },
              }}
            />
          ) : (
            <div className={styles.table}>
              <Skeleton count={8} />
            </div>
          )}
        </div>
      </div>

      {stats && <PlayerSeasonStats isGoalkeeper={isGoalkeeper} seasonStats={stats.season_stats} />}

      <PlayerClubTransfers transfers={player.club_transfers} />
    </div>
  );
};

export default PlayerPage;
