import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { ITournament } from "@/interfaces/Tournament";

export const useTournaments = (params?: { clubs?: boolean }, enabled?: boolean) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 60 * 24, // 1 day
    queryKey: ["tournaments", params],
    queryFn: async ({ signal }) => {
      return (
        await axios.get<IResponse<ITournament[]>>("/tournaments", {
          signal,
          params,
        })
      ).data.data;
    },
    enabled,
  });

  return query;
};
