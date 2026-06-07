import { createContext, useCallback, useContext, useMemo } from "react";
import { useRoundPlayers as useRoundPlayersQuery } from "@/api/query/useRoundPlayers";
import { useRoundPlayersContext } from "../RoundPlayersContext";
import { useRoundPlayersPageConfigurationContext } from "../RoundPlayersPageConfigurationContext";

const useRoundPlayersList = () => {
  const { requestFilterPayload, requestSortPayload } = useRoundPlayersContext();
  const { roundId } = useRoundPlayersPageConfigurationContext();

  const { data, fetchNextPage, hasNextPage, isFetchingNextPage, isFetching, isPending } =
    useRoundPlayersQuery({
      roundId,
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

const RoundPlayersListContext = createContext<null | ReturnType<typeof useRoundPlayersList>>(null);

export const useRoundPlayersListContext = () => {
  const context = useContext(RoundPlayersListContext);

  if (!context) {
    throw new Error("useRoundPlayersListContext must be used within a RoundPlayersListContext");
  }

  return context;
};

const RoundPlayersListContextProvider = ({ children }: { children: React.ReactNode }) => {
  return (
    <RoundPlayersListContext.Provider value={useRoundPlayersList()}>
      {children}
    </RoundPlayersListContext.Provider>
  );
};

export default RoundPlayersListContextProvider;
