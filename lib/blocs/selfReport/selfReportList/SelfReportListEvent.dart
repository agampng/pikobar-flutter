part of 'SelfReportListBloc.dart';

abstract class SelfReportListEvent extends Equatable {
  const SelfReportListEvent([List props = const <dynamic>[]]);
}

class SelfReportListLoad extends SelfReportListEvent {
  @override
  List<Object> get props => [];
}

class SelfReportListUpdated extends SelfReportListEvent {
  final QuerySnapshot selfReportList;

  const SelfReportListUpdated(this.selfReportList);

  @override
  List<Object> get props => [selfReportList];
}



