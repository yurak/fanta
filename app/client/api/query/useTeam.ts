import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { ITeam } from "@/interfaces/Team";

export const useTeam = (id: number) => {
  const query = useQuery({
    staleTime: 1000 * 60 * 10, // 10 minutes
    queryKey: ["team", id],
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<ITeam>>(`/teams/${id}`, { signal })).data.data;
    },
  });

  return query;
};
