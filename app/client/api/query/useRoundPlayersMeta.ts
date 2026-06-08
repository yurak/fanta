import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IRoundPlayersMeta } from "@/interfaces/RoundPlayer";

export const useRoundPlayersMeta = (roundId: number) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 30, // 30 minutes
    queryKey: ["round_players_meta", roundId],
    queryFn: async ({ signal }) => {
      return (
        await axios.get<IResponse<IRoundPlayersMeta>>(
          `/tournament_rounds/${roundId}/round_players/meta`,
          { signal }
        )
      ).data.data;
    },
  });

  return query;
};
