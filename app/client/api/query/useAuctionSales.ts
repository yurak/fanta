import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IAuctionSales } from "@/interfaces/AuctionSales";

export const useAuctionSales = (leagueId: number, auctionId: number) => {
  return useQuery({
    staleTime: 1000 * 60 * 10, // 10 minutes
    queryKey: ["auction", auctionId, "sales"],
    queryFn: async ({ signal }) => {
      return (
        await axios.get<IResponse<IAuctionSales>>(
          `/leagues/${leagueId}/auctions/${auctionId}/sales`,
          { signal },
        )
      ).data.data;
    },
  });
};
