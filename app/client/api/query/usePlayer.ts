import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IPlayerShow } from "@/interfaces/Player";

export const usePlayer = (id: number) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 10, // 10 minutes
    queryKey: ["player", id],
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<IPlayerShow>>(`/players/${id}`, { signal })).data.data;
    },
  });

  return query;
};
