import cn from "classnames";
import PlayerAvatar, { PlayerAvatarSkeleton } from "@/components/PlayerAvatar";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import TournamentsLoader from "@/components/loaders/TournamentsLoader";
import { formatNumber } from "@/helpers/formatNumber";
import { IPlayer } from "@/interfaces/Player";
import DataList from "@/ui/DataList";
import styles from "./PlayersListMobile.module.scss";
import Skeleton from "react-loading-skeleton";

const PlayerItem = ({
  avatar_path,
  club,
  name,
  first_name,
  average_base_score,
  average_total_score,
  position_classic_arr,
  appearances,
  teams_count,
}: IPlayer) => {
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
            <PlayerPositions positions={position_classic_arr} />
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
          <span className={styles.apps}>{`${formatNumber(appearances)} ${
            appearances === 1 ? "App" : "Apps"
          }`}</span>
          <span className={cn(styles.divider, styles.teams)} />
          <span className={styles.teams}>{`${formatNumber(teams_count)} ${
            appearances === 1 ? "Team" : "Teams"
          }`}</span>
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

const PlayersListMobile = ({
  items,
  isLoading,
  emptyStateComponent,
}: {
  items: IPlayer[],
  isLoading: boolean,
  emptyStateComponent: React.ReactNode,
}) => {
  return (
    <DataList
      dataSource={items}
      renderItem={(item) => <PlayerItem {...item} />}
      itemClassName={styles.item}
      itemKey={(item) => item.id}
      isLoading={isLoading}
      emptyStateComponent={emptyStateComponent}
      skeletonItems={15}
      skeletonRender={() => <PlayerItemSkeleton />}
    />
  );
};

export default PlayersListMobile;
