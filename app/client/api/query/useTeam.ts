import axios from "axios";
import { UseQueryOptions, useQueries, useQuery } from "@tanstack/react-query";
import { IResponse } from "../../interfaces/api/Response";
import { ITeam } from "../../interfaces/Team";

const getTeamQuery = (id: number): UseQueryOptions<ITeam, Error, ITeam, (string | number)[]> => ({
  staleTime: 1000 * 60 * 10, // 10 minutes
  queryKey: ["team", id],
  queryFn: async ({ signal }) => {
    return (await axios.get<IResponse<ITeam>>(`/teams/${id}`, { signal })).data.data;
  },
});

export const useTeam = (id: number) => {
  const query = useQuery(getTeamQuery(id));

  return query;
};

export const useTeams = (ids: number[]) => {
  const query = useQueries({
    queries: ids.map(getTeamQuery),
  });

  return query;
};
