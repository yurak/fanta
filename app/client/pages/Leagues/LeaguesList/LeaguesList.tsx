import { ILeaguesWithTournament } from "../interfaces";
import LeaguesListDesktop from "./LeaguesListDesktop";
import LeaguesListMobile from "./LeaguesListMobile";

import styles from "./LeaguesList.module.scss";

const LeaguesList = ({
  dataSource,
  isLoading,
}: {
  dataSource: ILeaguesWithTournament[],
  isLoading: boolean,
}) => {
  return (
    <>
      <div className={styles.desktop}>
        <LeaguesListDesktop dataSource={dataSource} isLoading={isLoading} />
      </div>
      <div className={styles.mobile}>
        <LeaguesListMobile dataSource={dataSource} isLoading={isLoading} />
      </div>
    </>
  );
};

export default LeaguesList;
