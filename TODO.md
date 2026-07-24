# TODO - Project tasks

- [ ] Create Expense Manager app UI using Liquid Glass design language with frosted translucent surfaces (no new/changed colors; use only provided palette)
  - [ ] Add missing glassLight/glassBorder in lib/utils/app_colors.dart (derived from existing palette only)
  - [ ] Create reusable glass widgets in lib/widget (GlassCard + shimmer highlight + press animations)
  - [ ] Refactor HomeScreen + ExpenseSummaryCard + ExpenseTile to use GlassCard
  - [ ] Refactor ContactDetailScreen, ConnectScreen, SettingsScreen, Add/Edit forms to glass UI
  - [ ] Adjust Splash/Lock screens for glass panels
  - [ ] Ensure all UI uses only the allowed palette (green/red only for success/error toasts/snackbars)
  - [ ] Run `flutter analyze`
  - [ ] Manual smoke test: add/edit/delete + navigation

- [ ] Fix delete behavior so totals update correctly in Home and Contact Detail after adding then deleting an entry
  - [ ] Ensure the deleted item is removed from Hive and the UI rebuilds using the correct index/mapping
  - [ ] Update ContactDetailScreen swipe-to-delete to delete by Hive key/index deterministically (avoid using `box.values.toList().indexOf(expense)` which can break)
  - [ ] (If needed) Update HomeScreen swipe-to-delete to delete by Hive object reference/key safely
  - [ ] Run `flutter analyze` and `flutter test` (if available) / manual smoke test

