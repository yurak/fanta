import { useTranslation } from "react-i18next";
import Link from "../Link";
import Popover from "../Popover";
import PopoverInputButton from "./PopoverInputButton";

const PopoverInput = ({
  label,
  selectedLabel,
  clearValue,
  children,
  subHeader,
}: {
  label: string,
  selectedLabel?: React.ReactNode,
  clearValue: () => void,
  children: React.ReactNode,
  subHeader?: React.ReactNode,
}) => {
  const { t } = useTranslation();

  const isPristine = !selectedLabel;

  return (
    <Popover
      title={label}
      renderedReference={(props) => (
        <PopoverInputButton
          {...props}
          placeholder={label}
          selectedLabel={selectedLabel}
          clearValue={clearValue}
          isPristine={isPristine}
        />
      )}
      footer={
        <Link asButton disabled={isPristine} onClick={clearValue}>
          {t("players.filters.clear")}
        </Link>
      }
      subHeader={subHeader}
    >
      {children}
    </Popover>
  );
};

export default PopoverInput;
