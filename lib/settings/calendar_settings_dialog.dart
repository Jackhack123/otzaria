import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/navigation/calendar_cubit.dart';
import 'package:otzaria/settings/settings_repository.dart';
import 'package:otzaria/widgets/rtl_text_field.dart';

/// Global function to display calendar settings dialog
/// Can be called from anywhere in the application
void showCalendarSettingsDialog(BuildContext context,
    {CalendarCubit? calendarCubit}) {
  // If Cubit is passed explicitly, use it, otherwise try to read from context
  CalendarCubit? existingCubit = calendarCubit;
  bool shouldCloseAfter = false;

  if (existingCubit == null) {
    try {
      existingCubit = context.read<CalendarCubit>();
    } catch (e) {
      // If no CalendarCubit is available, create a new one
      final settingsRepository = SettingsRepository();
      existingCubit = CalendarCubit(settingsRepository: settingsRepository);
      shouldCloseAfter = true;
    }
  }

  final cubit = existingCubit;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: cubit,
        child: _CalendarSettingsDialog(calendarCubit: cubit),
      );
    },
  ).then((_) {
    if (shouldCloseAfter) {
      cubit.close();
    }
  });
}

/// Calendar Settings Dialog with option to expand for city selection
class _CalendarSettingsDialog extends StatefulWidget {
  final CalendarCubit calendarCubit;

  const _CalendarSettingsDialog({required this.calendarCubit});

  @override
  State<_CalendarSettingsDialog> createState() =>
      _CalendarSettingsDialogState();
}

class _CalendarSettingsDialogState extends State<_CalendarSettingsDialog> {
  bool _showCitySearch = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      bloc: widget.calendarCubit,
      builder: (context, state) {
        return AlertDialog(
          title: const Text('Calendar Settings'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calendar Type:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  RadioGroup<CalendarType>(
                    groupValue: state.calendarType,
                    onChanged: (value) {
                      if (value != null) {
                        widget.calendarCubit.changeCalendarType(value);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        RadioListTile<CalendarType>(
                          title: Text('Hebrew Calendar'),
                          value: CalendarType.hebrew,
                        ),
                        RadioListTile<CalendarType>(
                          title: Text('Gregorian Calendar'),
                          value: CalendarType.gregorian,
                        ),
                        RadioListTile<CalendarType>(
                          title: Text('Combined Calendar'),
                          value: CalendarType.combined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'City:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showCitySearch = !_showCitySearch;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.selectedCity),
                            const SizedBox(width: 8),
                            Icon(
                              _showCitySearch
                                  ? FluentIcons.chevron_up_24_regular
                                  : FluentIcons.chevron_down_24_regular,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Expand for city search
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showCitySearch
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              _CitySearchWidget(
                                currentCity: state.selectedCity,
                                onCitySelected: (city) {
                                  widget.calendarCubit.changeCity(city);
                                  setState(() {
                                    _showCitySearch = false;
                                  });
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Notifications:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Notifications for Events'),
                    value: state.calendarNotificationsEnabled,
                    onChanged: (value) {
                      widget.calendarCubit
                          .changeCalendarNotificationsEnabled(value);
                    },
                  ),
                  if (state.calendarNotificationsEnabled)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0, left: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SwitchListTile(
                            title: const Text('Play Sound in Notification'),
                            value: state.calendarNotificationSound,
                            onChanged: (value) {
                              widget.calendarCubit
                                  .changeCalendarNotificationSound(value);
                            },
                          ),
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Reminder Time Before Event',
                            ),
                            initialValue: state.calendarNotificationTime,
                            items: const [
                              DropdownMenuItem(value: 60, child: Text('1 Hour')),
                              DropdownMenuItem(
                                  value: 720, child: Text('12 Hours')),
                              DropdownMenuItem(value: 1440, child: Text('1 Day')),
                              DropdownMenuItem(
                                  value: 2880, child: Text('2 Days')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                widget.calendarCubit
                                    .changeCalendarNotificationTime(value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

/// Widget for searching and selecting a city (embedded within the dialog)
class _CitySearchWidget extends StatefulWidget {
  final String currentCity;
  final ValueChanged<String> onCitySelected;

  const _CitySearchWidget({
    required this.currentCity,
    required this.onCitySelected,
  });

  @override
  State<_CitySearchWidget> createState() => _CitySearchWidgetState();
}

class _CitySearchWidgetState extends State<_CitySearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  late Map<String, Map<String, Map<String, dynamic>>> _filteredCities;

  @override
  void initState() {
    super.initState();
    _filteredCities = cityCoordinates;
    _searchController.addListener(_filterCities);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCities);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCities = cityCoordinates;
      } else {
        _filteredCities = {};
        cityCoordinates.forEach((country, cities) {
          final matchingCities = Map.fromEntries(cities.entries.where(
              (cityEntry) => cityEntry.key.toLowerCase().contains(query)));
          if (matchingCities.isNotEmpty) {
            _filteredCities[country] = matchingCities;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    _filteredCities.forEach((country, cities) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            country,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 16,
            ),
          ),
        ),
      );
      cities.forEach((city, data) {
        items.add(
          ListTile(
            title: Text(city),
            onTap: () {
              widget.onCitySelected(city);
            },
            dense: true,
          ),
        );
      });
      items.add(const Divider());
    });
    if (items.isNotEmpty) {
      items.removeLast(); // Remove last divider
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: RtlTextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Type city name...',
                prefixIcon: Icon(FluentIcons.search_24_regular),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 300,
            child: _filteredCities.isEmpty
                ? const Center(child: Text('No cities found'))
                : ListView(children: items),
          ),
        ],
      ),
    );
  }
}
