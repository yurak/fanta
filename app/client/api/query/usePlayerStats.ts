import axios from "axios";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IPlayerStats } from "@/interfaces/PlayerStats";

export const usePlayerStats = (id: number, seasonId?: number | null) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 10, // 10 minutes
    placeholderData: keepPreviousData,
    queryKey: ["player-stats", id, seasonId ?? "current"],
    queryFn: async ({ signal }) => {
      const params = seasonId ? { season_id: seasonId } : {};

      return (
        await axios.get<IResponse<IPlayerStats>>(`/players/${id}/stats`, { params, signal })
      ).data.data;
    },
  });

  return query;
};