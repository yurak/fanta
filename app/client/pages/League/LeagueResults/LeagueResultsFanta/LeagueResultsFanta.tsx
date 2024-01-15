import { useLeagueResults } from "../../../../api/query/useLeagueResults";
import { ILeagueFantaResults } from "../../../../interfaces/LeagueResults";
import LeagueResultsFantaTable from "./LeagueResultsFantaTable";

const LeagueResultsFanta = ({ leagueId }: { leagueId: number }) => {
  const leaguesResults = useLeagueResults<ILeagueFantaResults>(leagueId);

  return (
    <LeagueResultsFantaTable
      isLoading={leaguesResults.isLoading}
      leaguesResults={leaguesResults.data}
    />
  );
};

export default LeagueResultsFanta;
