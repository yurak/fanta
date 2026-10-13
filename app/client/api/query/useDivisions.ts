import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IDivisionsResponse } from "@/interfaces/Division";

export const useDivisions = (tournamentId: number, seasonId?: number) => {
  return useQuery({
    queryKey: ["tournament", tournamentId, "divisions", seasonId],
    enabled: Boolean(tournamentId),
    queryFn: async ({ signal }) => {
      return (
        await axios.get<IDivisionsResponse>(`/tournaments/${tournamentId}/divisions`, {
          signal,
          params: seasonId ? { season_id: seasonId } : undefined,
        })
      ).data;
    },
  });
};
