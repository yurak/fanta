import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IFieldingTeam } from "@/interfaces/RoundPlayer";

export const useRoundPlayerTeams = (roundId: number, roundPlayerId: number | null) => {
  return useQuery({
    enabled: roundPlayerId !== null,
    staleTime: 1000 * 60 * 5,
    queryKey: ["round_player_teams", roundId, roundPlayerId],
    queryFn: async ({ signal }) => {
      return (
        await axios.get<IResponse<IFieldingTeam[]>>(
          `/tournament_rounds/${roundId}/round_players/${roundPlayerId}/teams`,
          { signal }
        )
      ).data.data;
    },
  });
};
