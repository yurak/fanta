import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { ILeagueFantaResults, ILeagueResults } from "@/interfaces/LeagueResults";

export const useLeagueResults = <T extends ILeagueFantaResults | ILeagueResults>(id: number) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 10, // 10 minutes
    queryKey: ["league", id, "results"],
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<T[]>>(`/leagues/${id}/results`, { signal })).data.data;
    },
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
