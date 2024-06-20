import Drawer from "@/ui/Drawer";
import Button from "@/ui/Button";
import { RadioboxGroup } from "@/ui/Radiobox";
import { useState } from "react";
import { usePlayersSortContext } from "@/application/Players/PlayersSortContext";

const PlayersSortDrawer = ({ isOpen, close }: { isOpen: boolean, close: () => void }) => {
  const { value, setValue, sortOptions } = usePlayersSortContext();

  const [innerValue, setInnerValue] = useState(value);

  const onApply = () => {
    setValue(innerValue);
    close();
  };

  return (
    <Drawer
      title="Sort by"
      isOpen={isOpen}
      onClose={close}
      footer={
        <Button block onClick={onApply}>
          Apply
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
