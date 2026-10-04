import axios from "axios";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { IResponse } from "@/interfaces/api/Response";
import { IPlayerShow } from "@/interfaces/Player";
import { IWishlist, IWishlistToggle } from "@/interfaces/Wishlist";

const listsKey = ["wishlists"];
const listKey = (id: number) => ["wishlist", id];
const playerKey = (id: number) => ["player", id];
const playersKey = ["players"]; // the prefix every players-list query shares

export const useWishlists = (enabled?: boolean) => {
  return useQuery({
    queryKey: listsKey,
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<IWishlist[]>>("/wishlists", { signal })).data.data;
    },
    enabled,
  });
};

export const useWishlist = (id: number) => {
  return useQuery({
    queryKey: listKey(id),
    retry: false, // a private list answers 403 and retrying will not change that
    queryFn: async ({ signal }) => {
      return (await axios.get<IResponse<IWishlist>>(`/wishlists/${id}`, { signal })).data.data;
    },
  });
};

export const useShareWishlist = (id: number) => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (shared: boolean) => {
      return (await axios.patch<IResponse<IWishlist>>(`/wishlists/${id}`, { shared })).data.data;
    },
    onSuccess: (data) => {
      queryClient.setQueryData(listKey(id), data);
      queryClient.invalidateQueries({ queryKey: listsKey });
    },
  });
};

// The client says where it wants the heart to end up rather than asking for a flip, so a click
// against a stale page still does what the user saw and meant.
export const useWishlistPlayer = (playerId: number) => {
  const queryClient = useQueryClient();
  const key = playerKey(playerId);

  return useMutation({
    mutationFn: async (wanted: boolean) => {
      const response = wanted
        ? await axios.post<IResponse<IWishlistToggle>>("/wishlist_players", { player_id: playerId })
        : await axios.delete<IResponse<IWishlistToggle>>(`/wishlist_players/${playerId}`);

      return response.data.data;
    },
    onMutate: async (wanted) => {
      await queryClient.cancelQueries({ queryKey: key });
      const previous = queryClient.getQueryData<IPlayerShow>(key);

      if (previous) queryClient.setQueryData<IPlayerShow>(key, { ...previous, wishlisted: wanted });

      return { previous };
    },
    onError: (_error, _wanted, context) => {
      if (context?.previous) queryClient.setQueryData(key, context.previous);
    },
    onSuccess: (data) => {
      const stored = queryClient.getQueryData<IPlayerShow>(key);

      if (stored) {
        queryClient.setQueryData<IPlayerShow>(key, {
          ...stored,
          wishlisted: data.wishlisted,
          wishlist_id: data.wishlist.id,
        });
      }

      queryClient.invalidateQueries({ queryKey: listsKey });
      queryClient.invalidateQueries({ queryKey: listKey(data.wishlist.id) });
      // The table on a wishlist page is an ordinary players query narrowed by `wishlist_id`, and
      // that cache is both fresh for a minute and persisted for a day — without this the page
      // keeps serving the rows from before the heart was pressed.
      queryClient.invalidateQueries({ queryKey: playersKey });
    },
  });
};
