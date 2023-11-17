import { useState } from "react";
import { QueryClient } from "@tanstack/react-query";
import { createSyncStoragePersister } from "@tanstack/query-sync-storage-persister";
import { PersistQueryClientOptions } from "@tanstack/react-query-persist-client";
import packageJson from "../../../package.json";

export const useQueryClient = () => {
  const [queryClient] = useState(
    new QueryClient({
      defaultOptions: {
        queries: {
          staleTime: 1000 * 60 * 10, // 10 minutes
          refetchOnWindowFocus: false,
        },
      },
    })
  );

  const [persistOptions] = useState<Omit<PersistQueryClientOptions, "queryClient">>({
    persister: createSyncStoragePersister({
      storage: typeof window !== "undefined" ? window.localStorage : null,
    }),
    buster: packageJson.version,
  });

  return {
    queryClient,
    persistOptions,
  };
};
