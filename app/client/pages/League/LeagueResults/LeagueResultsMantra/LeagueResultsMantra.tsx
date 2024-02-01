import { useMemo } from "react";
import { useLeagueResults } from "../../../../api/query/useLeagueResults";
import { ILeagueFullData } from "../../../../interfaces/League";
import { ILeagueResults } from "../../../../interfaces/LeagueResults";
import PageHeading from "../../../../components/Heading";
import ChartIndicator from "../../../../assets/images/chartIndicator.svg";
import LeagueResultsMantraChart from "./LeagueResultsMantraChart";
import LeagueResultsMantraTable from "./LeagueResultsMantraTable";
import styles from "./LeagueResultsMantra.module.scss";

const LeagueResultsMantra = ({
  leagueData,
  leagueId,
}: {
  leagueData: ILeagueFullData,
  leagueId: number,
}) => {
  const leaguesResults = useLeagueResults<ILeagueResults>(leagueId);

  const isThereSomeChartData = useMemo(
    () => leaguesResults.data.some((item) => item.history.some(Boolean)),
    []
  );

  return (
    <>
      <LeagueResultsMantraTable
        promotion={leagueData.promotion}
        relegation={leagueData.relegation}
        teamsCount={leagueData.teams_count}
        leaguesResults={leaguesResults.data}
        isLoading={leaguesResults.isLoading}
      />
      {(leaguesResults.isLoading || isThereSomeChartData) && (
        <div className={styles.chart}>
          <PageHeading tag="h4" title="Leaders trend" titleIcon={<ChartIndicator />} />
          <LeagueResultsMantraChart
            leaguesResults={leaguesResults.data}
            isLoading={leaguesResults.isLoading}
          />
        </div>
      )}
    </>
  );
};

export default LeagueResultsMantra;
