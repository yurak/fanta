import { useMemo } from "react";
import { useSearchParamsContext } from "@/application/SearchParamsContext";

export const useHistoryFilter = <T extends object>(
  decodeFilter: (filter: Record<string, string>) => T,
  encodeFilter: (filter: T) => Record<string, string | null>
): [T, (value: T) => void] => {
  const { searchParams, setSearchParams } = useSearchParamsContext();

  const filter = useMemo(() => {
    const params = searchParams.getAll();

    return decodeFilter(params);
  }, []);

  const setFilter = (filter: T) => {
    setSearchParams(
      (prev) => {
        const encodedObject = encodeFilter(filter);

        Object.keys(encodedObject).forEach((key) => {
          const value = encodedObject[key] as string;
          prev.set(key, value);
        });

        return prev;
      },
      {
        replace: true,
      }
    );
  };

  return [filter, setFilter];
};
