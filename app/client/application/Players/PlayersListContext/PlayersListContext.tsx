import { createContext, useCallback, useContext, useMemo } from "react";
import { usePlayers as usePlayersQuery } from "@/api/query/usePlayers";
import { usePlayersContext } from "../PlayersContext";

const usePlayersList = () => {
  const { requestFilterPayload, requestSortPayload } = usePlayersContext();

  const { data, fetchNextPage, hasNextPage, isFetchingNextPage, isFetching, isPending } =
    usePlayersQuery({
      filter: requestFilterPayload,
      sort: requestSortPayload,
    });

  const items = useMemo(() => data?.pages.flatMap((page) => page.data) ?? [], [data]);

  const totalItemCount = useMemo(() => {
    if (!data) {
      return 0;
    }

    const lastPage = data.pages.length - 1;

    return data.pages[lastPage]?.meta.size ?? 0;
  }, [data]);

  const loadMore = useCallback(() => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  }, [hasNextPage, isFetchingNextPage, fetchNextPage]);

  const isLoading = isPending || (isFetching && !isFetchingNextPage);

  return {
    items,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isFetching,
    isPending,
    isLoading,
    totalItemCount,
    loadMore,
  };
};

const PlayersListContext = createContext<null | ReturnType<typeof usePlayersList>>(null);

export const usePlayersListContext = () => {
  const context = useContext(PlayersListContext);

  if (!context) {
    throw new Error("usePlayersListContext must be used within a PlayersListContext");
  }

  return context;
};

const PlayersListContextProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <PlayersListContext.Provider value={usePlayersList()}>{children}</PlayersListContext.Provider>
  );
};

export default PlayersListContextProvider;
