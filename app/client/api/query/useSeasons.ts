import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "../../interfaces/api/Response";
import { ISeason } from "../../interfaces/Season";

export const useSeasons = () => {
  const query = useQuery({
    queryKey: ["seasons"],
    queryFn: async () => {
      return (await axios.get<IResponse<ISeason[]>>("/seasons")).data.data;
    },
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
