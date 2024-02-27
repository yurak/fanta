import { useMemo } from "react";
import axios from "axios";
import { useDebounceValue } from "usehooks-ts";
import { keepPreviousData, useInfiniteQuery } from "@tanstack/react-query";
import { IPlayer } from "@/interfaces/Player";
import { ICollectionResponse } from "@/interfaces/api/Response";

export const usePlayers = ({ search, sortField }: { search: string, sortField: string | null }) => {
  const filter = useMemo(
    () => ({
      name: search,
    }),
    [search]
  );

  const order = useMemo(() => {
    if (!sortField) {
      return undefined;
    }

    return {
      field: sortField,
      direction: "asc",
    };
  }, [sortField]);

  const [debouncedFilter] = useDebounceValue(filter, 500);

  const query = useInfiniteQuery<ICollectionResponse<IPlayer[]>>({
    staleTime: 1000 * 60 * 10, // 10 minutes
    initialPageParam: 1,
    queryKey: ["players", debouncedFilter, order],
    queryFn: async ({ signal, pageParam: pageNumber }) => {
      return (
        await axios.get<ICollectionResponse<IPlayer[]>>("/players", {
          params: {
            filter: debouncedFilter,
            order,
            page: {
              number: pageNumber,
              size: 25,
            },
          },
          signal,
        })
      ).data;
    },
    placeholderData: keepPreviousData,
    getNextPageParam: ({ meta: { page } }) => {
      return page.current_page < page.total_pages ? page.current_page + 1 : undefined;
    },
  });

  return query;
};
