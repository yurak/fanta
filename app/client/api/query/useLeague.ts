import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { ILeagueFullData } from "../../interfaces/League";

export const useLeague = (id: number, enabled: boolean) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 10, // 30 minutes
    queryKey: ["league", id],
    queryFn: async ({ signal }) => {
      return (await axios.get<ILeagueFullData>(`/leagues/${id}`, { signal })).data;
    },
    enabled,
  });

  return query;
};
