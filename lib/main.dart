import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarEvent {
  String _title = "";
  bool _completed = false;
  late DateTime _day;

  CalendarEvent.fromFormattedString(String formattedString) {
    List<String> parsedString = formattedString.split(",");
    _title = parsedString[0];
    _day = DateTime.parse(parsedString[1]);
  }

  CalendarEvent(String title, DateTime day) {
    _title = title;
    _day = day;
  }

  @override
  String toString() {
    return "$_title,$_completed";
  }
}

void main() {
  runApp(const MaterialApp(
    title: "Daily Reminder",
    home: DailyReminderApp(),
  ));
}

class DailyReminderApp extends StatefulWidget {
  const DailyReminderApp({Key? key}) : super(key: key);

  @override
  DailyReminderAppState createState() => DailyReminderAppState();
}

class DailyReminderAppState extends State<DailyReminderApp> with WidgetsBindingObserver {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  DateTime? _selectedDay;
  final LinkedHashMap<DateTime, List<CalendarEvent>> _eventSource = LinkedHashMap<DateTime, List<CalendarEvent>>(
    equals: isSameDay,
  );


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    // Dummy eventSource TODO: use sharedpreferences
    _eventSource.addAll({
      DateTime.utc(2021, 11, 5):[CalendarEvent("Test",DateTime.utc(2021, 11, 5)), CalendarEvent("Test 2",DateTime.utc(2021, 11, 5))],
    });
   // _loadEventSource();
    _selectedEvents = ValueNotifier(_getEventsForDay(_focusedDay.value));
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  // Save _eventSource to sharedpreferences if the app is closed/stopped
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached){
      _saveEventSource();
      print("TESTING: SAVED EVENT SOURCE");
    }
  }

  void _loadEventSource() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<DateTime, List<CalendarEvent>> tempMap = [] as Map<DateTime, List<CalendarEvent>>;
    DateTime dateTimeTemp;
    // Loop through every DateTime String key entry in the shared preferences
    for(String dateTimeStringKey in prefs.getKeys()){
      // Parse the DateTime from the key String for indexing in the eventsource map
      dateTimeTemp = DateTime.parse(dateTimeStringKey);
      // Loop through each CalendarEvent String and convert to a CalendarEvent
      for (String calendarEventString in prefs.getStringList(dateTimeStringKey)!) {
        tempMap[dateTimeTemp]!.add(CalendarEvent.fromFormattedString(calendarEventString));
      }
    }
    // Populate _eventSource
    _eventSource.addAll(tempMap);
  }

  void _saveEventSource() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // List<String> tempDateTimeStringList = [];
    // for(MapEntry<DateTime, List<CalendarEvent>> entry in _eventSource.entries){
    //   // Convert all CalendarEvents to Strings
    //   for (var calendarEvent in entry.value) {
    //     tempDateTimeStringList.add(calendarEvent.toString());
    //   }
    //   // Set the DateTime String key to the list of CalendarEvent keys
    //   prefs.setStringList(entry.key.toString(), tempDateTimeStringList);
    //   tempDateTimeStringList.clear();
    // }
  }

  //// Calendar Functions

  // Use `selectedDayPredicate` to determine which day is currently selected.
  // If this returns true, then `day` will be marked as selected.
  // Using `isSameDay` is recommended to disregard
  // the time-part of compared DateTime objects.
  bool _selectedDayPredicate (day) {
    return isSameDay(_selectedDay, day);
  }

  // Update what day is selected and focused when a day is tapped
  void _onDaySelected (selectedDay, focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      // Call `setState()` when updating the selected day
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay.value = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  // Update the visible calendar
  void _onFormatChanged(format) {
    if (_calendarFormat != format) {
      // Call `setState()` when updating calendar format
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  // No need to call `setState()` here because we want to load back to
  // the previous focusedDay so the user doesn't lose their place
  void _onPageChanged(focusedDay) {
    _focusedDay.value = focusedDay;
  }

  // Event loader
  List<CalendarEvent> _getEventsForDay(DateTime day) {
    List<CalendarEvent> eventList = _eventSource[day] ?? [];
    return eventList;
  }

  // Get color for Checkbox state (always return black)
  Color getColor(Set<MaterialState> states) {
    return Colors.black;
  }

  void _deleteEvent(CalendarEvent event) {
    _eventSource[event._day]!.remove(event);
    _saveUpdatedDay(event._day,_eventSource[event._day]!);
    setState(() {
      _selectedEvents.value.remove(event);
    });
  }

  // Save an updated day with a list of CalendarEvents
  Future<void> _saveUpdatedDay(DateTime day, List<CalendarEvent> events) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Convert the list of CalendarEvents to Strings
    List<String> tempDateTimeStringList = [];
    for (var calendarEvent in events) {
      tempDateTimeStringList.add(calendarEvent.toString());
    }
    prefs.setStringList(day.toString(), tempDateTimeStringList);
  }

  void _editEvent(CalendarEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventEditWidget(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Daily Reminder App'),
        ),
        body: Column(
          children: [
            //ValueListenableBuilder<DateTime>(valueListenable: _focusedDay, builder: builder)
            TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay.value,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: _selectedDayPredicate,
              onDaySelected: _onDaySelected,
              onFormatChanged: _onFormatChanged,
              onPageChanged: _onPageChanged,
              eventLoader: (day) {
                return _getEventsForDay(day);
              },
            ),
            Expanded(
              child: ValueListenableBuilder<List<CalendarEvent>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                        ),
                        child: Slidable(
                          actionPane: const SlidableStrechActionPane(),
                          actionExtentRatio: 0.15,
                          child: ListTile(
                              leading: Checkbox(
                                checkColor: Colors.white,
                                fillColor: MaterialStateProperty.resolveWith(getColor),
                                value: value[index]._completed,
                                onChanged: (bool? changedValue) {
                                  setState((){
                                    value[index]._completed = changedValue!;
                                  });
                                },
                              ),
                              onTap: () => setState((){
                                value[index]._completed = !value[index]._completed;
                              }),
                              title: value[index]._completed ? Text('${value[index]}', style: const TextStyle(decoration: TextDecoration.lineThrough)) : Text('${value[index]}'),
                              tileColor: value[index]._completed ? Colors.black26 : Colors.white
                          ),
                          secondaryActions: <Widget> [
                            IconSlideAction(
                              caption: "Edit",
                              color: Colors.blue,
                              icon: Icons.create_outlined,
                              onTap: ()=> _editEvent(value[index]),
                            ),
                            IconSlideAction(
                              caption: "Delete",
                              color: Colors.red,
                              icon: Icons.delete_forever,
                              onTap: ()=> _deleteEvent(value[index]),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        )
      );
  }
}

class EventEditWidget extends StatelessWidget {
  const EventEditWidget({Key? key, required this.event}) : super(key: key);

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
   return Scaffold(
       appBar: AppBar(
         title: const Text('Daily Reminder App'),
       ),
       body: Column(
         children: <Widget>[
           TextFormField(
             decoration: const InputDecoration(
               border: InputBorder.none,
               hintText: 'Title',
             ),
             initialValue: event._title,
           ),
         ],
       )
     );
  }
}