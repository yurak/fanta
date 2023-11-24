import Skeleton from "react-loading-skeleton";
import LeagueStatus from "../../../../components/LeagueStatus";
import DataList from "../../../../ui/DataList";
import { ILeaguesWithTournament } from "../../interfaces";
import LeagueLoader from "../LeagueLoader";
import styles from "./LeaguesListMobile.module.scss";

const LeagueItem = ({ name, tournament, status, division, id }: ILeaguesWithTournament) => {
  return (
    <div className={styles.item}>
      {tournament && (
        <span className={styles.image}>
          <img src={tournament.logo} />
        </span>
      )}
      <div className={styles.content}>
        <div className={styles.contentTop}>
          <div className={styles.name}>{name}</div>
          <div className={styles.status}>
            <LeagueStatus status={status} />
          </div>
        </div>
        <div className={styles.contentBottom}>
          <LeagueLoader leagueId={id}>
            {(league) => (
              <span className={styles.details}>
                <span>{division}</span>
                {tournament && <span>{tournament?.name}</span>}
                <span>{`${league.season_start_year}-${league.season_end_year}`}</span>
                <span>🍻 #{league.round}</span>
              </span>
            )}
          </LeagueLoader>
        </div>
      </div>
    </div>
  );
};

const LeagueItemSkeleton = () => {
  return (
    <div className={styles.item}>
      <span className={styles.image}>
        <Skeleton height={24} />
      </span>
      <div className={styles.content}>
        <div className={styles.contentTop}>
          <div className={styles.name}>
            <Skeleton />
          </div>
          <div className={styles.status}>
            <Skeleton />
          </div>
        </div>
        <div className={styles.contentBottom}>
          <Skeleton width="60%" />
        </div>
      </div>
    </div>
  );
};

const LeaguesListMobile = ({
  dataSource,
  isLoading,
}: {
  dataSource: ILeaguesWithTournament[];
  isLoading: boolean;
}) => {
  return (
    <DataList
      dataSource={dataSource}
      renderItem={(item) => <LeagueItem {...item} />}
      itemKey={(item) => item.id}
      itemLink={(item) => item.link}
      skeletonRender={LeagueItemSkeleton}
      isLoading={isLoading}
    />
  );
};

export default LeaguesListMobile;
