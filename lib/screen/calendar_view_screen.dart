import 'package:flutter/material.dart';

/// CalendarView provides a visual calendar representation of the menstrual cycle
/// It shows period days, ovulation, and fertile window in both month and year views
class CalendarView extends StatefulWidget {
  final int cycleLengthDays;
  final int periodLengthDays;
  final DateTime lastPeriodDate;
  final Function(DateTime)? onPeriodDateChanged;

  const CalendarView({
    super.key,
    required this.cycleLengthDays,
    required this.periodLengthDays,
    required this.lastPeriodDate,
    this.onPeriodDateChanged,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showMonthView = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  late DateTime _currentPeriodStartDate;
  late List<DateTime> _periodStartDates;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentPeriodStartDate = widget.lastPeriodDate;
    _updatePeriodDates();

    // Set initial month view to the month containing current period
    _selectedMonth = _currentPeriodStartDate.month;
    _selectedYear = _currentPeriodStartDate.year;
  }

  @override
  void didUpdateWidget(CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastPeriodDate != widget.lastPeriodDate) {
      _currentPeriodStartDate = widget.lastPeriodDate;
      _updatePeriodDates();

      // Update view to show the new period month
      _selectedMonth = _currentPeriodStartDate.month;
      _selectedYear = _currentPeriodStartDate.year;
    }
  }

  void _updatePeriodDates() {
    _periodStartDates = _calculateFuturePeriodDates();
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    return Column(
      children: [
        // Tab selection for Month/Year
        Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showMonthView = true;
                  });
                  _tabController.animateTo(0);
                },
                child: Text(
                  'Month',
                  style: TextStyle(
                    color: _showMonthView ? Colors.black : Colors.grey,
                    fontWeight:
                        _showMonthView ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showMonthView = false;
                  });
                  _tabController.animateTo(1);
                },
                child: Text(
                  'Year',
                  style: TextStyle(
                    color: !_showMonthView ? Colors.black : Colors.grey,
                    fontWeight:
                        !_showMonthView ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Month/Year navigation
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    if (_showMonthView) {
                      // In month view, navigate to previous month
                      if (_selectedMonth > 1) {
                        _selectedMonth--;
                      } else {
                        _selectedMonth = 12;
                        _selectedYear--;
                      }
                    } else {
                      // In year view, navigate to previous year
                      _selectedYear--;
                    }
                  });
                },
              ),
              Text(
                _showMonthView
                    ? "${_getMonthName(_selectedMonth)} $_selectedYear"
                    : "$_selectedYear",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    if (_showMonthView) {
                      // In month view, navigate to next month
                      if (_selectedMonth < 12) {
                        _selectedMonth++;
                      } else {
                        _selectedMonth = 1;
                        _selectedYear++;
                      }
                    } else {
                      // In year view, navigate to next year
                      _selectedYear++;
                    }
                  });
                },
              ),
            ],
          ),
        ),

        // Only show weekday header in month view
        if (_showMonthView)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children:
                  ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

        // Calendar grid
        Expanded(
          child:
              _showMonthView
                  ? _buildMonthView(_periodStartDates, today)
                  : _buildYearView(_periodStartDates, today),
        ),
      ],
    );
  }

  Widget _buildMonthView(List<DateTime> periodStartDates, DateTime today) {
    // Create a DateTime for the first day of selected month
    final DateTime viewMonth = DateTime(_selectedYear, _selectedMonth, 1);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount:
          _getDaysInMonth(_selectedYear, _selectedMonth) +
          _getFirstWeekdayOfMonth(_selectedYear, _selectedMonth),
      itemBuilder: (context, index) {
        // Empty cells for days before the 1st of the month
        final int firstWeekdayOfMonth = _getFirstWeekdayOfMonth(
          _selectedYear,
          _selectedMonth,
        );
        if (index < firstWeekdayOfMonth) {
          return Container();
        }
        // Actual day of the month
        final int day = index - firstWeekdayOfMonth + 1;
        final DateTime currentDate = DateTime(
          _selectedYear,
          _selectedMonth,
          day,
        );

        // Check if this day is a period day or special day
        bool isPeriodDay = false;
        bool isOvulationDay = false;
        bool isFertileDay = false;

        // Check period days for all dates regardless of past/future
        for (DateTime periodStart in periodStartDates) {
          // Check if the current date is within periodLengthDays from any period start date
          if (currentDate.difference(periodStart).inDays >= 0 &&
              currentDate.difference(periodStart).inDays <
                  widget.periodLengthDays) {
            isPeriodDay = true;
          }

          // Calculate ovulation day (approximately 14 days before next period)
          DateTime nextPeriodAfterThis = periodStart.add(
            Duration(days: widget.cycleLengthDays),
          );
          DateTime ovulation = nextPeriodAfterThis.subtract(
            const Duration(days: 14),
          );

          // Check if it's an ovulation day
          if (currentDate.year == ovulation.year &&
              currentDate.month == ovulation.month &&
              currentDate.day == ovulation.day) {
            isOvulationDay = true;
          }

          // Check if it's in fertile window (5 days before ovulation and ovulation day)
          DateTime fertileWindowStart = ovulation.subtract(
            const Duration(days: 5),
          );
          if (currentDate.isAfter(
                fertileWindowStart.subtract(const Duration(days: 1)),
              ) &&
              currentDate.isBefore(ovulation.add(const Duration(days: 1)))) {
            isFertileDay = true;
          }
        }

        // Determine if it's today
        final bool isToday =
            currentDate.year == today.year &&
            currentDate.month == today.month &&
            currentDate.day == today.day;

        // Check if this is the current period start date
        final bool isCurrentPeriodStartDate =
            currentDate.year == _currentPeriodStartDate.year &&
            currentDate.month == _currentPeriodStartDate.month &&
            currentDate.day == _currentPeriodStartDate.day;

        // Past days should be less prominent
        final bool isPastDay = currentDate.isBefore(today);

        // Determine background color
        Color? backgroundColor;
        Color textColor = isPastDay ? Colors.grey : Colors.black;

        if (isPeriodDay) {
          backgroundColor = Colors.pink;
          textColor = Colors.white;
        } else if (isOvulationDay) {
          backgroundColor = Colors.green[700];
          textColor = Colors.white;
        } else if (isFertileDay) {
          backgroundColor = Colors.green[300];
        }

        // Special border for current period start date or today
        Border? border;
        if (isToday) {
          border = Border.all(color: Colors.blue, width: 2);
        } else if (isCurrentPeriodStartDate) {
          border = Border.all(color: Colors.deepPurple, width: 2);
        }

        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: border,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: textColor,
                fontWeight:
                    (isToday || isCurrentPeriodStartDate)
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearView(List<DateTime> periodStartDates, DateTime today) {
    // Show a grid of 12 months with mini calendars for the year view
    List<int> months = List.generate(12, (index) => index + 1);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        int month = months[index];
        return _buildMiniMonth(_selectedYear, month, periodStartDates, today);
      },
    );
  }

  Widget _buildMiniMonth(
    int year,
    int month,
    List<DateTime> periodStartDates,
    DateTime today,
  ) {
    return GestureDetector(
      onTap: () {
        // When user taps on a mini month, navigate to that month in month view
        setState(() {
          _selectedMonth = month;
          _showMonthView = true;
          _tabController.animateTo(0);
        });
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            // Month name
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Text(
                _getMonthName(month),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            // Mini calendar grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(2),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                ),
                itemCount:
                    _getDaysInMonth(year, month) +
                    _getFirstWeekdayOfMonth(year, month),
                itemBuilder: (context, index) {
                  // Empty cells for days before the 1st of the month
                  final int firstWeekdayOfMonth = _getFirstWeekdayOfMonth(
                    year,
                    month,
                  );
                  if (index < firstWeekdayOfMonth) {
                    return Container();
                  }

                  // Actual day of the month
                  final int day = index - firstWeekdayOfMonth + 1;
                  final DateTime currentDate = DateTime(year, month, day);

                  // Check if this day is a period day
                  bool isPeriodDay = false;

                  // Check period days for all dates without conditions
                  for (DateTime periodStart in periodStartDates) {
                    if (currentDate.difference(periodStart).inDays >= 0 &&
                        currentDate.difference(periodStart).inDays <
                            widget.periodLengthDays) {
                      isPeriodDay = true;
                      break;
                    }
                  }

                  // Determine if it's today
                  final bool isToday =
                      currentDate.year == today.year &&
                      currentDate.month == today.month &&
                      currentDate.day == today.day;

                  // Check if this is the current period start date
                  final bool isCurrentPeriodStartDate =
                      currentDate.year == _currentPeriodStartDate.year &&
                      currentDate.month == _currentPeriodStartDate.month &&
                      currentDate.day == _currentPeriodStartDate.day;

                  // Past days should be less prominent
                  final bool isPastDay = currentDate.isBefore(today);

                  // Special border for edited date or today
                  Border? border;
                  if (isToday) {
                    border = Border.all(color: Colors.blue, width: 1);
                  } else if (isCurrentPeriodStartDate) {
                    border = Border.all(color: Colors.deepPurple, width: 1);
                  }

                  return Container(
                    margin: const EdgeInsets.all(0.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPeriodDay ? Colors.pink : null,
                      border: border,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color:
                              isPeriodDay
                                  ? Colors.white
                                  : (isPastDay
                                      ? Colors.grey[400]
                                      : Colors.black),
                          fontSize: 7,
                          fontWeight:
                              (isToday || isCurrentPeriodStartDate)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get the first weekday of a month (0 = Monday, 6 = Sunday)
  int _getFirstWeekdayOfMonth(int year, int month) {
    final firstDayOfMonth = DateTime(year, month, 1);
    // Adjust weekday to have Monday as 0, Sunday as 6
    return (firstDayOfMonth.weekday - 1) % 7;
  }

  // Helper method to get the number of days in a month
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  // Calculate period dates based on the current period start date
  List<DateTime> _calculateFuturePeriodDates() {
    List<DateTime> periodStartDates = [];
    final DateTime today = DateTime.now();

    // Always add the current period start date first
    periodStartDates.add(_currentPeriodStartDate);

    // Calculate future periods
    DateTime futureDate = _currentPeriodStartDate;
    for (int i = 0; i < 12; i++) {
      futureDate = futureDate.add(Duration(days: widget.cycleLengthDays));
      periodStartDates.add(futureDate);
    }

    return periodStartDates;
  }

  String _getMonthName(int month) {
    const List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }
}
