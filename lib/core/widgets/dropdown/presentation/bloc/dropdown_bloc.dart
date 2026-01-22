import 'package:flutter_bloc/flutter_bloc.dart';
import 'dropdown_event.dart';
import 'dropdown_state.dart';

class DropdownBloc<T> extends Bloc<DropdownEvent<T>, DropdownState<T>> {
  DropdownBloc({T? initial})
      : super(DropdownState<T>(selectedValue: initial)) {
    on<DropdownValueChanged<T>>((event, emit) {
      emit(state.copyWith(selectedValue: event.newValue));
    });
  }
}
