import { ILeagueFullData } from "../../../../interfaces/League";

const LeagueResultsMantra = ({
  leagueData,
  leagueId,
}: {
  leagueData: ILeagueFullData;
  leagueId: number;
}) => {
  console.log({ leagueData, leagueId });
  return <>test</>;
};

export default LeagueResultsMantra;
