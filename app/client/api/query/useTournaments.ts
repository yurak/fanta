import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "../../interfaces/api/Response";
import { ITournament } from "../../interfaces/Tournament";

export const useTournaments = () => {
  const query = useQuery({
    queryKey: ["tournaments"],
    queryFn: async () => {
      return (await axios.get<IResponse<ITournament[]>>("/tournaments")).data.data;
    },
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
