import { useLeague } from "@/api/query/useLeague";
import { ILeagueFullData } from "@/interfaces/League";
import QueryLoader, { IQueryLoaderBaseProps } from "../QueryLoader";

interface IProps extends IQueryLoaderBaseProps<ILeagueFullData> {
  leagueId: number,
}

const LeagueLoader = ({ leagueId, ...restProps }: IProps) => {
  return (
    <QueryLoader
      useQuery={(isIntersecting: boolean) => useLeague(leagueId, isIntersecting)}
      {...restProps}
    />
  );
};

export default LeagueLoader;
