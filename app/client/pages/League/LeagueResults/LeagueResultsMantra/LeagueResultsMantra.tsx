import { useState } from "react";
import { useLeagueResults } from "../../../../api/query/useLeagueResults";
import { ILeagueFullData } from "../../../../interfaces/League";
import { ILeagueResults } from "../../../../interfaces/LeagueResults";
import PageHeading from "../../../../components/Heading";
import Switcher from "../../../../ui/Switcher";
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
  const [isLoading, setIsLoading] = useState(false);

  const leaguesResults = useLeagueResults<ILeagueResults>(leagueId);

  return (
    <>
      <LeagueResultsMantraTable
        promotion={leagueData.promotion}
        relegation={leagueData.relegation}
        teamsCount={leagueData.teams_count}
        leaguesResults={leaguesResults.data}
        isLoading={isLoading || leaguesResults.isLoading}
      />
      <div className={styles.chart}>
        <Switcher
          checked={isLoading}
          onChange={setIsLoading}
          label={isLoading ? "Turn off loading" : "Turn on loading"}
        />
        <PageHeading tag="h4" title="Leaders trend" titleIcon={<ChartIndicator />} />
        <LeagueResultsMantraChart
          leaguesResults={leaguesResults.data}
          isLoading={isLoading || leaguesResults.isLoading}
        />
      </div>
    </>
  );
};

export default LeagueResultsMantra;
