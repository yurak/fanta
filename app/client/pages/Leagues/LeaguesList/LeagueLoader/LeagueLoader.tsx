import Skeleton from "react-loading-skeleton";
import { useLeague } from "../../../../api/query/useLeague";
import { ILeagueFullData } from "../../../../interfaces/League";
import { useIntersectionObserver } from "../../../../hooks/useIntersectionObserver";

const LeagueLoader = ({
  leagueId,
  children,
}: {
  leagueId: number;
  children: (item: ILeagueFullData) => React.ReactNode;
}) => {
  const [ref, entry] = useIntersectionObserver<HTMLSpanElement>({ rootMargin: "50%" });
  const { data, isLoading } = useLeague(leagueId, entry?.isIntersecting ?? false);

  return <span ref={ref}>{isLoading || !data ? <Skeleton /> : children(data)}</span>;
};

export default LeagueLoader;
