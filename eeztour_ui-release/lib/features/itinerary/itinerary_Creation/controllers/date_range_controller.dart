import 'package:flutter/foundation.dart';

class DateRangeController extends ChangeNotifier {
  DateTime? _startDate; 
  DateTime? _endDate;
  
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  
  // Update both dates at once
  void updateDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }
  
  // Clear date selection
  void clearDates() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }
  
  // Calculate number of nights
  int get numberOfNights {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }
}