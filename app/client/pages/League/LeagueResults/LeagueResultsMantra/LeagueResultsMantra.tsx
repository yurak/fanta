import { ILeagueFullData } from "../../../../interfaces/League";
import LeagueResultsMantraChart from "./LeagueResultsMantraChart";
import LeagueResultsMantraTable from "./LeagueResultsMantraTable";

const LeagueResultsMantra = ({
  leagueData,
  leagueId,
}: {
  leagueData: ILeagueFullData;
  leagueId: number;
}) => {
  return (
    <>
      <LeagueResultsMantraTable
        promotion={leagueData.promotion}
        relegation={leagueData.relegation}
        teamsCount={leagueData.teams_count}
        leagueId={leagueId}
      />
      <LeagueResultsMantraChart leagueId={leagueId} teamsCount={leagueData.teams_count} />
    </>
  );
};

export default LeagueResultsMantra;
