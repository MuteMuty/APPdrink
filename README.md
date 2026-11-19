# Drink

**A Flutter app that reminds you to drink water during the day.**

## Why it exists

A small Flutter project from Aug 2020.

## How it works

You set a start time, an end time and an interval (in steps of 15 minutes). The app schedules a daily local notification, "Drink now!", at each reminder time between the two, using `flutter_local_notifications`. A switch turns all reminders off. The settings are saved on the device with `shared_preferences`. A second screen shows quotes about water.

It doesn't log how much you drink.

## Run it

Needs an old Flutter release (the project predates null safety).

```sh
flutter pub get
flutter run
```

## Tech

Flutter, Dart, `flutter_local_notifications`, `rxdart`, `shared_preferences`.

## Status

Finished in Aug 2020 and not maintained. Made by [Erik Pahor](https://github.com/MuteMuty).
