import { ILeaguesWithTournament } from "../interfaces";
import LeaguesListDesktop from "./LeaguesListDesktop";

const LeaguesList = ({
  dataSource,
  isLoading,
}: {
  dataSource: ILeaguesWithTournament[];
  isLoading: boolean;
}) => {
  return <LeaguesListDesktop dataSource={dataSource} isLoading={isLoading} />;
};

export default LeaguesList;
