import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "../../interfaces/api/Response";
import { ILeagueFullData } from "../../interfaces/League";

export const useLeague = (id: number, enabled?: boolean) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 30, // 30 minutes
    queryKey: ["league", id],
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<ILeagueFullData>>(`/leagues/${id}`, { signal })).data.data;
    },
    enabled,
  });

  return query;
};
