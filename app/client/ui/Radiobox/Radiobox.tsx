import CheckedIcon from "@/assets/icons/checkbox.svg";
import RadioCheckboxAbstract, {
  IRadioCheckboxAbstractProps,
} from "../abstract/RadioCheckboxAbstract";

interface IProps extends Omit<IRadioCheckboxAbstractProps, "onChange" | "type" | "icon"> {
  onChange: (checked: boolean) => void,
}

const Checkbox = ({ checked, onChange, label, disabled, block }: IProps) => {
  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.checked);
  };

  return (
    <RadioCheckboxAbstract
      type="radio"
      checked={checked}
      onChange={onChangeHandler}
      icon={<>{checked && <CheckedIcon />}</>}
      label={label}
      block={block}
      disabled={disabled}
    />
  );
};

export default Checkbox;
