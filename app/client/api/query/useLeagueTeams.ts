import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";

export interface ILeagueTeam {
  id: number,
  human_name: string,
  logo_path: string,
}

export const useLeagueTeams = (leagueId?: number) => {
  return useQuery({
    staleTime: 1000 * 60 * 10,
    queryKey: ["league-teams", leagueId],
    queryFn: async ({ signal }) => {
      return (
        await axios.get<IResponse<ILeagueTeam[]>>(`/leagues/${leagueId}/teams`, { signal })
      ).data.data;
    },
    enabled: !!leagueId,
  });
};
