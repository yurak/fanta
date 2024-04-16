import { useTournaments } from "@/api/query/useTournaments";
import { ITournament } from "@/interfaces/Tournament";
import QueryLoader, { IQueryLoaderBaseProps } from "../QueryLoader";

const TournamentsLoader = (props: IQueryLoaderBaseProps<ITournament[]>) => {
  return (
    <QueryLoader
      useQuery={(isIntersecting: boolean) => useTournaments({}, isIntersecting)}
      {...props}
    />
  );
};

export default TournamentsLoader;
