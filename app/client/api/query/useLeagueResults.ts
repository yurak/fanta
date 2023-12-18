import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "../../interfaces/api/Response";
import { ILeagueResults } from "../../interfaces/LeagueResults";

export const useLeagueResults = (id: number | null) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 10, // 10 minutes
    queryKey: ["league", id, "results"],
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<ILeagueResults[]>>(`/leagues/${id}/results`, { signal }))
        .data.data;
    },
    enabled: Boolean(id),
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
