import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { ICollectionResponse } from "../../interfaces/api/Response";
import { ITournament } from "../../interfaces/Tournament";

export const useTournaments = () => {
  const query = useQuery({
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
