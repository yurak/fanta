import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IAuctionDrops } from "@/interfaces/AuctionDrops";

const queryKey = (auctionId: number) => ["auction", auctionId, "drops"];
const url = (leagueId: number, auctionId: number) => `/leagues/${leagueId}/auctions/${auctionId}/drops`;

export const useAuctionDrops = (leagueId: number, auctionId: number) => {
  return useQuery({
    queryKey: queryKey(auctionId),
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<IAuctionDrops>>(url(leagueId, auctionId), { signal })).data.data;
    },
  });
};

export const useUpdateDrops = (leagueId: number, auctionId: number) => {
  const queryClient = useQueryClient();
  const key = queryKey(auctionId);

  return useMutation({
    mutationFn: async (playerIds: number[]) => {
      return (
        await axios.patch<IResponse<IAuctionDrops>>(url(leagueId, auctionId), { player_ids: playerIds })
      ).data.data;
    },
    // optimistic: flip statuses + refresh stats immediately, reconcile with the server on success
    onMutate: async (playerIds) => {
      await queryClient.cancelQueries({ queryKey: key });
      const previous = queryClient.getQueryData<IAuctionDrops>(key);

      if (previous) {
        const selected = new Set(playerIds);
        const transferableSpent = previous.players
          .filter((p) => selected.has(p.id))
          .reduce((sum, p) => sum + (p.price ?? 0), 0);

        queryClient.setQueryData<IAuctionDrops>(key, {
          ...previous,
          team: {
            ...previous.team,
            players_dropped: playerIds.length,
            income: transferableSpent,
            possible_budget: previous.team.budget + transferableSpent,
          },
          players: previous.players.map((p) =>
            p.status === "left" ? p : { ...p, status: selected.has(p.id) ? "transferable" : "untouchable" }),
        });
      }

      return { previous };
    },
    onError: (_error, _playerIds, context) => {
      if (context?.previous) queryClient.setQueryData(key, context.previous);
    },
    onSuccess: (data) => {
      queryClient.setQueryData(key, data); // server is the source of truth (limit + budget)
    },
  });
};
