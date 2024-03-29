import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { ILeague } from "@/interfaces/League";
import { useMemo } from "react";

export const useLeagues = ({ season, tournament }: { season?: number, tournament?: number }) => {
  const filter = useMemo(
    () => ({
      season_id: season,
      tournament_id: tournament,
    }),
    [season, tournament]
  );

  const query = useQuery({
    staleTime: 1000 * 60 * 30, // 30 minutes
    queryKey: ["leagues", filter],
    queryFn: async ({ signal }) => {
      return (
        await axios.get<IResponse<ILeague[]>>("/leagues", {
          params: {
            filter,
          },
          signal,
        })
      ).data.data;
    },
    enabled: Boolean(season),
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
