import Checkbox from "./Checkbox";
import RadioCheckboxGroupAbstract, {
  IRadioCheckboxGroupAbstractProps,
} from "@/ui/abstract/RadioCheckboxGroupAbstract";

interface IProps<Option extends object, ID extends string | number>
  extends Omit<
    IRadioCheckboxGroupAbstractProps<Option, ID>,
    "isChecked" | "onChange" | "Component"
  > {
  value: ID[],
  onChange: (value: ID[]) => void,
}

const CheckboxGroup = <Option extends object, ID extends string | number>({
  value,
  onChange,
  ...props
}: IProps<Option, ID>) => {
  const onChangeHandler = (optionId: ID, optionValue: boolean) => {
    if (optionValue) {
      onChange([...new Set([...value, optionId])]);
    } else {
      onChange(value.filter((v) => optionId !== v));
    }
  };

  const isChecked = (id: ID) => value.includes(id);

  return (
    <RadioCheckboxGroupAbstract
      Component={Checkbox}
      onChange={onChangeHandler}
      isChecked={isChecked}
      {...props}
    />
  );
};

export default CheckboxGroup;
