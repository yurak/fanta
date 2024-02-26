import { useMemo } from "react";
import { useSearchParams } from "react-router-dom";

export const useSearchParam = <T = string>(key: string) => {
  const [searchParams, setSearchParams] = useSearchParams();

  const value = searchParams.get(key);

  const setValue = (value?: T) => {
    setSearchParams(
      (prev) => {
        if (value) {
          prev.set(key, value.toString());
          return prev;
        }

        prev.delete(key);

        return prev;
      },
      {
        replace: true,
      }
    );
  };

  return useMemo<[string | null, (value?: T | null) => void]>(
    () => [value, setValue],
    [value, setValue]
  );
};
