import Radiobox from "./Radiobox";
import RadioCheckboxGroupAbstract, {
  IRadioCheckboxGroupAbstractProps,
} from "@/ui/abstract/RadioCheckboxGroupAbstract";

interface IProps<Option extends object, ID extends string | number | object | null>
  extends Omit<
    IRadioCheckboxGroupAbstractProps<Option, ID>,
    "isChecked" | "onChange" | "Component"
  > {
  value: ID,
  onChange: (value: ID) => void,
  isChecked?: (value: NonNullable<ID>) => boolean,
}

const RadioboxGroup = <Option extends object, ID extends string | number | object | null>({
  value,
  onChange,
  isChecked,
  ...props
}: IProps<Option, ID>) => {
  const _isChecked = isChecked ?? ((id: NonNullable<ID>) => value === id);

  return (
    <RadioCheckboxGroupAbstract
      Component={Radiobox}
      onChange={onChange}
      isChecked={_isChecked}
      {...props}
    />
  );
};

export default RadioboxGroup;
