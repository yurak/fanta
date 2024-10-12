import Drawer from "@/ui/Drawer";
import Button from "@/ui/Button";
import { RadioboxGroup } from "@/ui/Radiobox";
import { useState } from "react";
import { usePlayersSortContext } from "@/application/Players/PlayersSortContext";
import { useTranslation } from "react-i18next";

const PlayersSortDrawer = ({ isOpen, close }: { isOpen: boolean, close: () => void }) => {
  const { value, setValue, sortOptions } = usePlayersSortContext();
  const { t } = useTranslation();

  const [innerValue, setInnerValue] = useState(value);

  const onApply = () => {
    setValue(innerValue);
    close();
  };

  return (
    <Drawer
      title={t("players.sorter.sortBy")}
      isOpen={isOpen}
      onClose={close}
      footer={
        <Button block onClick={onApply}>
          {t("players.sorter.apply")}
        </Button>
      }
      placement="bottom"
    >
      <RadioboxGroup
        options={sortOptions}
        formatOptionLabel={(option) => option.label}
        getOptionValue={(option) => ({
          sortBy: option.sortBy,
          sortOrder: option.sortOrder,
        })}
        isChecked={(option) =>
          innerValue?.sortBy === option.sortBy && innerValue.sortOrder === option.sortOrder
        }
        getOptionKey={(option) => `${option.sortBy}-${option.sortOrder}`}
        onChange={(value) => setInnerValue(value)}
        value={value}
      />
    </Drawer>
  );
};

export default PlayersSortDrawer;
