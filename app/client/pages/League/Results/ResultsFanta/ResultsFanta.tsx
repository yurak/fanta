import { useLeagueResults } from "../../../../api/query/useLeagueResults";
import { ILeagueFantaResults } from "../../../../interfaces/LeagueResults";
import ResultsFantaTable from "./ResultsFantaTable";

const ResultsFanta = ({ leagueId }: { leagueId: number }) => {
  const leaguesResults = useLeagueResults<ILeagueFantaResults>(leagueId);

  return (
    <ResultsFantaTable isLoading={leaguesResults.isLoading} leaguesResults={leaguesResults.data} />
  );
};

export default ResultsFanta;
