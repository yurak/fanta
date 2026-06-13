import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import Drawer from "@/ui/Drawer";
import Button from "@/ui/Button";
import { RadioboxGroup } from "@/ui/Radiobox";
import {
  ISortOption,
  ISortValue,
  useRoundPlayersSortContext,
} from "@/application/RoundPlayers/RoundPlayersSortContext";

const toValue = (option?: ISortOption | null): ISortValue | null =>
  option ? { sortBy: option.sortBy, sortOrder: option.sortOrder } : null;

const RoundPlayersSortDrawer = ({ isOpen, close }: { isOpen: boolean, close: () => void }) => {
  const { selectedSort, sortOptions, applySort } = useRoundPlayersSortContext();
  const { t } = useTranslation();

  const [innerValue, setInnerValue] = useState<ISortValue | null>(toValue(selectedSort));

  useEffect(() => {
    if (isOpen) {
      setInnerValue(toValue(selectedSort));
    }
  }, [isOpen]);

  const onApply = () => {
    applySort(innerValue);
    close();
  };

  return (
    <Drawer
      title={t("round_players_page.sorter.sort_by")}
      isOpen={isOpen}
      onClose={close}
      placement="bottom"
      footer={
        <Button block onClick={onApply}>
          {t("round_players_page.sorter.apply")}
        </Button>
      }
    >
      <RadioboxGroup<ISortOption, ISortValue | null>
        options={sortOptions}
        value={innerValue}
        formatOptionLabel={(option) => option.label}
        getOptionValue={(option) => ({ sortBy: option.sortBy, sortOrder: option.sortOrder })}
        isChecked={(value) =>
          innerValue?.sortBy === value.sortBy && innerValue?.sortOrder === value.sortOrder
        }
        getOptionKey={(option) => `${option.sortBy}-${option.sortOrder}`}
        onChange={(value) => setInnerValue(value)}
      />
    </Drawer>
  );
};

export default RoundPlayersSortDrawer;
