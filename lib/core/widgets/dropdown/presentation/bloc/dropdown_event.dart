abstract class DropdownEvent<T> {}

class DropdownValueChanged<T> extends DropdownEvent<T> {
  final T? newValue;
  DropdownValueChanged(this.newValue);
}
