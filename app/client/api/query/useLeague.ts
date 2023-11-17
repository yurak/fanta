import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { ILeagueFullData } from "../../interfaces/League";

export const useLeague = (id: number) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 10, // 10 minutes
    queryKey: ["league", id],
    queryFn: async ({ signal }) => {
      return (await axios.get<ILeagueFullData>(`/leagues/${id}`, { signal })).data;
    },
  });

  return query;
};
