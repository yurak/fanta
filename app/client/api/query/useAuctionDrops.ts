import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IAuctionDrops } from "@/interfaces/AuctionDrops";

const queryKey = (auctionId: number) => ["auction", auctionId, "drops"];
const url = (leagueId: number, auctionId: number) => `/leagues/${leagueId}/auctions/${auctionId}/drops`;

// The endpoint answers 404 once dropping is over and 422 when too many players are selected, so the
// page can tell "this auction has moved on" from "that selection was refused".
export const isDropsClosedError = (error: unknown) =>
  axios.isAxiosError(error) && error.response?.status === 404;

export const useAuctionDrops = (leagueId: number, auctionId: number) => {
  return useQuery({
    queryKey: queryKey(auctionId),
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<IAuctionDrops>>(url(leagueId, auctionId), { signal })).data.data;
    },
    // The endpoint answers 404 once the sales phase is over, and the page turns that into a redirect
    // to the sales list — retrying it three times would only make the visitor wait for it.
    retry: (failureCount, error) => {
      if (axios.isAxiosError(error) && error.response?.status === 404) return false;

      return failureCount < 3;
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
