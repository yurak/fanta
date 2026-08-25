import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IAuctionsIndex } from "@/interfaces/Auctions";

export const useAuctions = (leagueId: number) => {
  return useQuery({
    queryKey: ["league", leagueId, "auctions"],
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<IAuctionsIndex>>(`/leagues/${leagueId}/auctions`, { signal })).data.data;
    },
  });
};
