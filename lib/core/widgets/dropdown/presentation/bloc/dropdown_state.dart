class DropdownState<T> {
  final T? selectedValue;

  const DropdownState({this.selectedValue});

  DropdownState<T> copyWith({T? selectedValue}) {
    return DropdownState<T>(
      selectedValue: selectedValue ?? this.selectedValue,
    );
  }
}
