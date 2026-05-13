import { useState } from "react";
import { useSearchParamsContext } from "@/application/SearchParamsContext";

export const useHistorySearch = (defaultSearch = ""): [string, (value: string) => void] => {
  const { searchParams, setSearchParams } = useSearchParamsContext();

  const [search, _setSearch] = useState(searchParams.get("s", true) ?? defaultSearch);

  const setSearch = (search: string) => {
    _setSearch(search);

    setSearchParams(
      (prev) => {
        if (search) {
          prev.set("s", search, true);
        } else {
          prev.delete("s");
        }

        return prev;
      },
      {
        replace: true,
      }
    );
  };

  return [search, setSearch];
};
