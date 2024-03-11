import { useMediaQuery } from "usehooks-ts";
import { ILeaguesWithTournament } from "../interfaces";
import LeaguesListDesktop from "./LeaguesListDesktop";
import LeaguesListMobile from "./LeaguesListMobile";

const LeaguesList = ({
  dataSource,
  isLoading,
}: {
  dataSource: ILeaguesWithTournament[],
  isLoading: boolean,
}) => {
  const isMobile = useMediaQuery("(max-width: 768px)");

  if (isMobile) {
    return <LeaguesListMobile dataSource={dataSource} isLoading={isLoading} />;
  }

  return <LeaguesListDesktop dataSource={dataSource} isLoading={isLoading} />;
};

export default LeaguesList;
