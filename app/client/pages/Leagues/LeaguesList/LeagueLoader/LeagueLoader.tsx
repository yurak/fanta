import Skeleton from "react-loading-skeleton";
import { useLeague } from "@/api/query/useLeague";
import { ILeagueFullData } from "@/interfaces/League";
import { useIntersectionObserver } from "@/hooks/useIntersectionObserver";

const LeagueLoader = ({
  leagueId,
  children,
  skeleton = <Skeleton />,
}: {
  leagueId: number,
  children: (item: ILeagueFullData) => React.ReactNode,
  skeleton?: React.ReactNode,
}) => {
  const [ref, entry] = useIntersectionObserver<HTMLSpanElement>({ rootMargin: "50%" });
  const { data, isLoading } = useLeague(leagueId, entry?.isIntersecting ?? false);

  return <div ref={ref}>{isLoading || !data ? skeleton : children(data)}</div>;
};

export default LeagueLoader;
