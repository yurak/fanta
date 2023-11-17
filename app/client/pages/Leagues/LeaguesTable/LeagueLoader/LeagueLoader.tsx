import Skeleton from "react-loading-skeleton";
import { useLeague } from "../../../../api/query/useLeague";
import { ILeagueFullData } from "../../../../interfaces/League";

const LeagueLoader = ({
  leagueId,
  children,
}: {
  leagueId: number;
  children: (item: ILeagueFullData) => React.ReactNode;
}) => {
  const { data, isLoading } = useLeague(leagueId);

  if (isLoading || !data) {
    return <Skeleton />;
  }

  return children(data);
};

export default LeagueLoader;
