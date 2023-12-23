import { useLeagueResults } from "../../../../api/query/useLeagueResults";
import { ILeagueFullData } from "../../../../interfaces/League";
import LeagueResultsMantraChart from "./LeagueResultsMantraChart";
import LeagueResultsMantraTable from "./LeagueResultsMantraTable";
import styles from "./LeagueResultsMantra.module.scss";
import PageHeading from "../../../../components/Heading";

const LeagueResultsMantra = ({
  leagueData,
  leagueId,
}: {
  leagueData: ILeagueFullData;
  leagueId: number;
}) => {
  const leaguesResults = useLeagueResults(leagueId);

  return (
    <>
      <LeagueResultsMantraTable
        promotion={leagueData.promotion}
        relegation={leagueData.relegation}
        teamsCount={leagueData.teams_count}
        leaguesResults={leaguesResults.data}
        isLoading={leaguesResults.isLoading}
      />
      <div className={styles.chart}>
        <PageHeading
          tag="h4"
          title="Leaders trend"
          titleIcon="⛰" //TODO: update icon
        />
        <LeagueResultsMantraChart
          teamsCount={leagueData.teams_count}
          leaguesResults={leaguesResults.data}
          isLoading={leaguesResults.isLoading}
        />
      </div>
    </>
  );
};

export default LeagueResultsMantra;
