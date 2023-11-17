import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { ILeagueFullData } from "../../interfaces/League";

export const useLeague = (id: number) => {
  const query = useQuery({
    queryKey: ["league", id],
    queryFn: async () => {
      return (await axios.get<ILeagueFullData>(`/leagues/${id}`)).data;
    },
  });

  return query;
};
