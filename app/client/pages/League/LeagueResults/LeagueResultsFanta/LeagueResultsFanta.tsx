import { useLeagueResults } from "../../../../api/query/useLeagueResults";
import { ILeagueFullData } from "../../../../interfaces/League";

const LeagueResultsFanta = ({
  leagueData,
  leagueId,
}: {
  leagueData: ILeagueFullData;
  leagueId: number;
}) => {
  const leaguesResults = useLeagueResults(leagueId);
  console.log({ leagueData, leagueId, leaguesResults });
  return <>loading...</>;
};

export default LeagueResultsFanta;
