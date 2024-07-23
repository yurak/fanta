import cn from "classnames";
import Skeleton from "react-loading-skeleton";
import PlayerAvatar, { PlayerAvatarSkeleton } from "@/components/PlayerAvatar";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import TournamentsLoader from "@/components/loaders/TournamentsLoader";
import { formatNumber } from "@/helpers/formatNumber";
import { IPlayer } from "@/interfaces/Player";
import DataList from "@/ui/DataList";
import { usePlayersListContext } from "@/application/Players/PlayersListContext";
import styles from "./PlayersListMobile.module.scss";
import { useTranslation } from "react-i18next";

const PlayerItem = ({
  avatar_path,
  club,
  name,
  first_name,
  average_base_score,
  average_total_score,
  position_classic_arr,
  appearances,
  appearances_max,
  teams_count,
  teams_count_max,
}: IPlayer) => {
  const { t } = useTranslation();

  return (
    <>
      <PlayerAvatar className={styles.avatar} avatarSrc={avatar_path} clubKitSrc={club.kit_path} />
      <div className={styles.info}>
        <div className={styles.top}>
          <div className={styles.name}>
            {first_name} {name}
          </div>
          <div className={styles.score}>
            {Number(average_base_score) > 0 && (
              <span>
                {formatNumber(Number(average_base_score), {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                })}
              </span>
            )}
            <span className={styles.totalScore}>
              {formatNumber(Number(average_total_score), {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              })}
            </span>
          </div>
        </div>
        <div className={styles.bottom}>
          <span>
            <PlayerPositions position={position_classic_arr} />
          </span>
          {club.tournament_id && (
            <>
              <span>
                <TournamentsLoader>
                  {(tournaments) => {
                    const tournament = tournaments.find((t) => t.id === club.tournament_id);

                    if (!tournament) {
                      return "-";
                    }

                    return (
                      <div className={styles.logo}>
                        <img src={tournament.logo} alt={tournament.name} />
                      </div>
                    );
                  }}
                </TournamentsLoader>
              </span>
              <span className={styles.divider} />
            </>
          )}
          <span>
            <div className={styles.logo}>
              <img src={club.logo_path} alt={club.name} />
            </div>
          </span>
          <span className={styles.divider} />
          <span className={styles.apps}>
            {formatNumber(appearances)}
            <span className={styles.grey}>
              {appearances > 0 && `(${formatNumber(appearances_max)})`}
            </span>{" "}
            {`${appearances === 1 ? t("players.results.app") : t("players.results.apps")}`}
          </span>
          <span className={cn(styles.divider, styles.teams)} />
          <span className={styles.teams}>
            {formatNumber(teams_count)}
            <span className={styles.grey}>
              {teams_count > 0 && `(${formatNumber(teams_count_max)})`}
            </span>{" "}
            {`${appearances === 1 ? t("players.results.team") : t("players.results.teams")}`}
          </span>
        </div>
      </div>
    </>
  );
};

const PlayerItemSkeleton = () => {
  return (
    <>
      <PlayerAvatarSkeleton className={styles.avatar} />
      <div className={styles.info}>
        <div className={styles.top}>
          <div className={styles.name}>
            <Skeleton width={150} />
          </div>
          <div className={styles.score}>
            <Skeleton width={50} />
          </div>
        </div>
        <div className={styles.bottom}>
          <Skeleton width={200} />
        </div>
      </div>
    </>
  );
};

const PlayersListMobile = ({ emptyStateComponent }: { emptyStateComponent: React.ReactNode }) => {
  const { items, isLoading, hasNextPage, loadMore } = usePlayersListContext();

  return (
    <DataList
      itemLink={(item) => `/players/${item.id}`}
      dataSource={items}
      renderItem={(item) => <PlayerItem {...item} />}
      itemClassName={styles.item}
      itemKey={(item) => item.id}
      isLoading={isLoading}
      isLoadingMore={hasNextPage}
      onLoadMore={loadMore}
      emptyStateComponent={emptyStateComponent}
      skeletonItems={15}
      skeletonRender={() => <PlayerItemSkeleton />}
    />
  );
};

export default PlayersListMobile;
