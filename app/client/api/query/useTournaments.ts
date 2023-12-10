import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { ICollectionResponse } from "../../interfaces/api/Response";
import { ITournament } from "../../interfaces/Tournament";

export const useTournaments = () => {
  const query = useQuery({
    staleTime: 1000 * 60 * 60 * 24, // 1 day
    queryKey: ["tournaments"],
    queryFn: async ({ signal }) => {
      return (await axios.get<ICollectionResponse<ITournament[]>>("/tournaments", { signal })).data
        .data;
    },
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
