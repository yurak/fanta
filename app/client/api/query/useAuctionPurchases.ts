import axios from "axios";
import { useQuery } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IAuctionPurchases } from "@/interfaces/AuctionPurchases";

export const useAuctionPurchases = (leagueId: number, auctionId: number) => {
  return useQuery({
    staleTime: 1000 * 60 * 10, // 10 minutes
    queryKey: ["auction", auctionId, "purchases"],
    queryFn: async ({ signal }) => {
      return (
        await axios.get<IResponse<IAuctionPurchases>>(
          `/leagues/${leagueId}/auctions/${auctionId}/purchases`,
          { signal },
        )
      ).data.data;
    },
  });
};
