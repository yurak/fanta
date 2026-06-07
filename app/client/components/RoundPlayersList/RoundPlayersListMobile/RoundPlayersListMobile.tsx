import Skeleton from "react-loading-skeleton";
import { useTranslation } from "react-i18next";
import PlayerAvatar, { PlayerAvatarSkeleton } from "@/components/PlayerAvatar";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { formatNumber } from "@/helpers/formatNumber";
import { IRoundPlayer } from "@/interfaces/RoundPlayer";
import DataList from "@/ui/DataList";
import { useRoundPlayersListContext } from "@/application/RoundPlayers/RoundPlayersListContext";
import { useRoundPlayersPageConfigurationContext } from "@/application/RoundPlayers/RoundPlayersPageConfigurationContext";
import styles from "@/components/PlayersList/PlayersListMobile/PlayersListMobile.module.scss";

const scoreFormat = { minimumFractionDigits: 2, maximumFractionDigits: 2 };

const RoundPlayerItem = ({
  avatar_path,
  kit_path,
  club,
  name,
  first_name,
  base_score,
  result_score,
  position_classic_arr,
  appearances,
  main_appearances,
  nationality,
}: IRoundPlayer) => {
  const { t } = useTranslation();
  const { fanta, national } = useRoundPlayersPageConfigurationContext();

  return (
    <>
      <PlayerAvatar className={styles.avatar} avatarSrc={avatar_path} clubKitSrc={kit_path ?? ""} />
      <div className={styles.info}>
        <div className={styles.top}>
          <div className={styles.name}>
            {first_name} {name}
          </div>
          <div className={styles.score}>
            {Number(base_score) > 0 && <span>{formatNumber(Number(base_score), scoreFormat)}</span>}
            <span className={styles.totalScore}>
              {formatNumber(Number(result_score), scoreFormat)}
            </span>
          </div>
        </div>
        <div className={styles.bottom}>
          <span>
            <PlayerPositions position={position_classic_arr} />
          </span>
          <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
            {national && nationality && (
              <span className={`flag-icon flag-icon-${nationality.toLowerCase()}`} />
            )}
            <span className={styles.divider} />
            <div className={styles.logo}>
              <img src={club.logo_path} alt={club.name} />
            </div>
          </span>
          {fanta && appearances !== null && (
            <>
              <span className={styles.divider} />
              <span className={styles.apps}>
                {formatNumber(appearances)} {t("round_players_page.apps")}
              </span>
              <span className={styles.divider} />
              <span className={styles.apps}>
                {formatNumber(main_appearances ?? 0)} {t("round_players_page.main")}
              </span>
            </>
          )}
        </div>
      </div>
    </>
  );
};

const RoundPlayerItemSkeleton = () => (
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

const RoundPlayersListMobile = ({
  emptyStateComponent,
}: {
  emptyStateComponent: React.ReactNode,
}) => {
  const { items, isLoading, hasNextPage, loadMore } = useRoundPlayersListContext();

  return (
    <DataList
      itemLink={(item) => `/players/${item.player_id}`}
      dataSource={items}
      renderItem={(item) => <RoundPlayerItem {...item} />}
      itemClassName={styles.item}
      itemKey={(item) => item.id}
      isLoading={isLoading}
      isLoadingMore={hasNextPage}
      onLoadMore={loadMore}
      emptyStateComponent={emptyStateComponent}
      skeletonItems={15}
      skeletonRender={() => <RoundPlayerItemSkeleton />}
    />
  );
};

export default RoundPlayersListMobile;
