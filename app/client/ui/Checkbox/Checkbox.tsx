import CheckedIcon from "@/assets/icons/checkbox.svg";
import IndeterminatedIcon from "@/assets/icons/indeterminate.svg";
import RadioCheckboxAbstract, {
  IRadioCheckboxAbstractProps,
} from "../abstract/RadioCheckboxAbstract";

interface IProps extends Omit<IRadioCheckboxAbstractProps, "onChange" | "type" | "icon"> {
  onChange: (checked: boolean) => void,
}

const Checkbox = ({ checked, onChange, indeterminate, label, disabled, block }: IProps) => {
  const isIndeterminate = !checked && indeterminate;

  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.checked);
  };

  return (
    <RadioCheckboxAbstract
      type="checkbox"
      checked={checked}
      onChange={onChangeHandler}
      icon={
        <>
          {checked && <CheckedIcon />}
          {isIndeterminate && <IndeterminatedIcon />}
        </>
      }
      indeterminate={isIndeterminate}
      label={label}
      block={block}
      disabled={disabled}
    />
  );
};

export default Checkbox;
