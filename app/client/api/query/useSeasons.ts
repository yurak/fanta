import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { ICollectionResponse } from "../../interfaces/api/Response";
import { ISeason } from "../../interfaces/Season";

export const useSeasons = () => {
  const query = useQuery({
    staleTime: 1000 * 60 * 60 * 24, // 1 day
    queryKey: ["seasons"],
    queryFn: async ({ signal }) => {
      return (await axios.get<ICollectionResponse<ISeason[]>>("/seasons", { signal })).data.data;
    },
  });

  return {
    ...query,
    data: query.data ?? [],
  };
};
