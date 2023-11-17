import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { ICollectionResponse } from "../../interfaces/api/Response";
import { ILeague } from "../../interfaces/League";
import { useMemo } from "react";

export const useLeagues = ({ season, tournament }: { season?: number; tournament?: number }) => {
  const filter = useMemo(
    () => ({
      season_id: season,
      tournament_id: tournament,
    }),
    [season, tournament]
  );

  const query = useQuery({
    queryKey: ["leagues", filter],
    queryFn: async () => {
      return (
        await axios.get<ICollectionResponse<ILeague[]>>("/leagues", {
          params: {
            filter,
          },
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
