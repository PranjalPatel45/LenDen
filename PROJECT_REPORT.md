# Expense Manager App - Complete Project Report

## 1. Project Overview

### App Name
**Expense Manager**

### Tagline
*Track • Lent • Borrowed*

### Concept
The Expense Manager is a comprehensive personal finance tracking application designed to help users manage their expenses, track money lent to others, and record borrowed amounts. The app provides a secure, visually appealing interface with modern glassmorphism design elements.

### Platform
- Flutter (Cross-platform: Android, iOS, Web, Desktop)

### Version
1.0.0

---

## 2. Core Features

### 2.1 Security & Authentication
- **PIN-based Lock Screen**: 4-digit PIN creation and verification
- **Biometric Authentication**: Fingerprint/Face ID quick unlock support
- **Secure Data Storage**: PIN stored in Hive local database
- **First-time Setup**: Automatic PIN creation flow on first launch
- **Change PIN**: Option to update existing PIN from settings

### 2.2 Expense Management
- **Add Expenses**: Create new expense entries with title, amount, date, type, and optional reason
- **Edit Expenses**: Swipe left on any expense to edit its details
- **Delete Expenses**: Swipe right to delete with confirmation
- **Expense Types**: 
  - **Lent**: Money given to others
  - **Borrowed**: Money taken from others

### 2.3 Financial Dashboard
- **Monthly Summary Card**: Displays current month's financial overview
  - Total Lent amount
  - Total Borrowed amount
  - Net Balance (Lent - Borrowed)
- **Real-time Calculations**: Automatically updates based on current month's expenses
- **Currency Support**: 20+ currencies with symbol and code display

### 2.4 Contact Management (Connect Feature)
- **Contact Integration**: Link expenses to contacts using device contacts
- **Prefill Contact Info**: Auto-fill contact name and phone number when adding transactions
- **Contact Details Screen**: View contact-specific expense history

### 2.5 Settings & Customization
- **Currency Selection**: Choose from 20 supported currencies
- **Currency Persistence**: Selection saved locally using Hive
- **App Settings**: Access to app configuration options

### 2.6 User Interface
- **Glassmorphism Design**: Modern frosted glass UI elements
- **Splash Screen**: Animated loading screen with floating circles and progress dots
- **Smooth Animations**: Entry animations, shake effects for wrong PIN, hover effects
- **Responsive Layout**: Adapts to different screen sizes
- **Dark/Light Theme**: Material 3 design system

---

## 3. App Flow & Navigation

```
Splash Screen (3 seconds)
    ↓
Lock Screen (First Launch: PIN Setup Mode)
    ↓
Home Screen (Main Dashboard)
    ├── Home Tab (Expense List + Summary)
    ├── Connect Tab (Contact Management)
    └── Settings Tab (App Configuration)
```

### Navigation Flow Details:

1. **App Launch**: SplashScreen displays for 3 seconds with animations
2. **Security Check**: LockScreen appears for PIN entry or biometric auth
3. **Main App**: HomeScreen with bottom navigation
4. **Add Expense**: Floating Action Button → FormScreen
5. **Edit Expense**: Swipe left on expense item → EditExpenseScreen
6. **Contact Flow**: ConnectScreen → Contact Detail → Prefill Add Todo

---

## 4. Data Models

### 4.1 Expense Model
```dart
- title: String (Description/Contact name)
- amount: double (Transaction amount)
- date: String (ISO date format)
- type: String ('Lent' or 'Borrowed')
- contactName: String? (Optional contact)
- phoneNumber: String? (Optional phone)
- reason: String? (Optional description)
```

### 4.2 Todo Model (Legacy/Planned)
```dart
- title: String
- subtitle: String
- date: String
```

---

## 5. Technical Stack

### 5.1 Dependencies
- **flutter**: Core framework
- **hive**: ^2.2.3 - Local NoSQL database
- **hive_flutter**: ^1.1.0 - Flutter integration for Hive
- **permission_handler**: ^12.0.3 - Runtime permissions
- **flutter_contacts**: ^2.2.2 - Contact management
- **local_auth**: ^3.0.2 - Biometric authentication
- **cupertino_icons**: ^1.0.8 - iOS-style icons

### 5.2 Dev Dependencies
- **flutter_test**: Testing framework
- **flutter_lints**: ^6.0.0 - Code quality
- **hive_generator**: ^2.0.1 - Model code generation
- **build_runner**: ^2.4.9 - Code generation runner

### 5.3 Storage
- **Hive Boxes**:
  - `expenses` - Stores all expense records
  - `settings` - Stores app preferences (currency, PIN)

---

## 6. Color Scheme

### 6.1 Primary Palette
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Background (Off White) | `#F8F9FA` | Main background |
| Card / Surface | `#FBFAFF` | Cards, surfaces |
| Primary Text | `#2A2D32` | Primary text, headings |
| Secondary Text | `#000000` | Secondary text, labels |
| Primary (Soft Lavender) | `#CDB4FF` | Secondary buttons, badges, charts |
| Primary Dark | `#B8A0E6` | Hover states |
| Accent (Baby Pink) | `#F8BBD0` | Soft accents, illustrations |
| Highlight (Powder Blue) | `#7EB6FF` | Primary buttons, active states, CTA |
| Success (Soft Green) | `#A8E6CF` | Success messages, confirmations |
| Error (Soft Red) | `#FFB4B4` | Error messages, warnings |

### 6.2 Additional Colors
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Soft Peach | `#FFE5B4` | Decorative elements |
| White | `#FFFFFF` | Cards, surfaces |
| Black | `#000000` | Primary text |
| Grey | `#9CA3AF` | Disabled states |
| Light Grey | `#E5E7EB` | Borders, dividers |

### 6.3 Glassmorphism Surfaces
| Surface | Description | Alpha Value |
|---------|-------------|-------------|
| glassLight | Frosted glass base | 0.14 |
| glassBorder | Subtle border | 0.26 |
| glassCard | Card surfaces | 0.72 |
| glassSheet | Sheet overlays | 0.82 |
| glassInputFill | Input backgrounds | 0.55 |
| glassNav | Navigation bar | 0.72 |

### 6.4 Glass Gradients
- **glassShimmer**: Diagonal shimmer effect (white to background)
- **glassHighlight**: Vertical highlight glow effect

### 6.5 Theme Configuration
- **Material Design**: Material 3 enabled
- **Primary Color**: Highlight (#7EB6FF)
- **AppBar**: Highlight color background, primary text foreground
- **FAB**: Highlight background, white foreground
- **Bottom Nav**: White background, highlight selected, primary text unselected
- **Cards**: Card surface (#FBFAFF) with 2px elevation, 12px radius
- **Buttons**: 10px radius, highlight background, primary text foreground
- **Input Fields**: 10px radius, primary color border at 35% opacity (default), #3600A3 (focused), primary text labels
- **SnackBar**: Floating behavior, neutral (#3600A3), success (#0B843D), error (#E22412)

---

## 7. Screen-by-Screen Details

### 7.1 Splash Screen
**Purpose**: Animated loading screen on app launch

**Key Elements**:
- Gradient background (background → light blue tones)
- 4 floating decorative circles with animation
- 8 animated decorative dots in circular pattern
- App icon with glass effect (receipt icon)
- "Expense" (light weight) / "Manager" (bold) text
- Tagline: "Track • Lent • Borrowed"
- Animated progress dots loading indicator

**Animations**:
- Fade in + Scale in (entry)
- Slide up for text elements
- Floating circles with sine wave motion
- Pulsing progress dots

**Duration**: 3 seconds → Navigates to LockScreen

---

### 7.2 Lock Screen
**Purpose**: Secure app access with PIN or biometrics

**Two Modes**:
1. **Setup Mode** (First launch or Change PIN):
   - Shield icon with gradient
   - "Secure Your App" / "Create a 4-digit PIN" text
   - Two PIN input fields (Enter + Confirm)
   - Modern PIN input with glass background
   - Set PIN / Update PIN button

2. **Unlock Mode**:
   - Lock icon with glow effect
   - "Welcome Back" / "Enter your PIN to continue"
   - 4 PIN dot indicators (empty vs filled)
   - Shake animation on wrong PIN
   - Number pad (1-9, 0, delete)
   - Biometric quick unlock button (if available)

**Background Effects**:
- Particle system (12 floating particles)
- Animated decorative circles
- Gradient background

**Security Features**:
- 4-digit PIN only
- Wrong PIN shake + haptic feedback
- Biometric fallback option
- PIN saved securely in Hive

---

### 7.3 Home Screen
**Purpose**: Main dashboard showing expense overview

**Structure**:
- **App Bar**: Dynamic title based on selected tab
- **ExpenseSummaryCard**: Monthly financial overview
- **Expense List**: Scrollable list of all expenses
  - Empty state with icon and message
  - Swipe left to edit
  - Swipe right to delete
- **FAB**: Add new expense button

**ExpenseSummaryCard Displays**:
- Total Balance (Lent - Borrowed)
- Total Lent amount
- Total Borrowed amount
- Current month filter applied
- Currency symbol display

**Interactions**:
- Swipe gestures for edit/delete
- Pull to refresh (ListView)
- Tap to view details (via EditExpenseScreen)

---

### 7.4 Add Expense Screen (FormScreen)
**Purpose**: Form for creating new expense entries

**Fields**:
1. Amount (with currency prefix)
2. Title / Contact Name (prefillable)
3. Type (Dropdown: Lent/Borrowed)
4. Reason (optional)
5. Date (date picker)

**Features**:
- Default date = today
- Currency-aware amount field
- Glass-styled input fields
- Cancel/Submit buttons
- Prefill support for contact flow

**Validation**:
- Amount required (numeric)
- Title required
- Date required
- Type selection required

---

### 7.5 Edit Expense Screen
**Purpose**: Modify existing expense entries

**Similar to Add Expense Screen** with:
- Pre-filled data from existing expense
- Update operation instead of create
- Navigation back to HomeScreen on save

---

### 7.6 Connect Screen
**Purpose**: Contact management integration

**Features**:
- Browse device contacts
- Link contacts to expenses
- View contact expense history
- Quick add transaction from contact

**Flow**:
ConnectScreen → Contact Detail → Add Todo (with prefill)

---

### 7.7 Contact Detail Screen
**Purpose**: View all expenses for a specific contact

**Displays**:
- Contact information
- Total lent to contact
- Total borrowed from contact
- List of all transactions with this contact

---

### 7.8 Settings Screen
**Purpose**: App configuration and preferences

**Features**:
- Currency selection (20 options)
- Change PIN option
- App information
- Other preferences

---

## 8. Widgets & Reusable Components

### 8.1 Glass Widgets (glass_widgets.dart)
Custom glassmorphism-themed widgets:
- **GlassCard**: Frosted glass card container
- **GlassInput**: Glass-styled text input
- **GlassButton**: Glass-effect button
- Properties:
  - Adjustable blur radius (12px)
  - Border opacity (0.26-0.28)
  - Fill opacity (0.55-0.82)

### 8.2 App Navigation Bar (app_nav_bar.dart)
**Bottom Navigation** with 3 tabs:
- Home (Expense overview)
- Connect (Contacts)
- Settings (Configuration)

**Theme Integration**:
- White background
- Highlight for selected item
- Grey for unselected
- 8px elevation shadow

### 8.3 Expense Tile (expense_tile.dart)
Displays individual expense in list:
- Title/Contact name
- Amount (with currency)
- Date
- Type indicator (Lent/Borrowed)
- Swipe actions (edit/delete)

### 8.4 Expense Summary Card (expense_summary_card.dart)
Compact financial dashboard:
- Large total balance figure
- Lent amount section
- Borrowed amount section
- Visual distinction for positive/negative balance

---

## 9. Utility Files

### 9.1 App Colors (app_colors.dart)
- Centralized color constants
- Theme configuration
- Glassmorphism color definitions
- Gradients for glass effects

### 9.2 Currency Helper (currency_helper.dart)
**Supported Currencies** (20 total):
- USD ($) - US Dollar
- EUR (€) - Euro
- GBP (£) - British Pound
- JPY (¥) - Japanese Yen
- INR (₹) - Indian Rupee
- KRW (₩) - South Korean Won
- RUB (₽) - Russian Ruble
- BRL (R$) - Brazilian Real
- AUD (A$) - Australian Dollar
- CAD (C$) - Canadian Dollar
- CHF - Swiss Franc
- ILS (₪) - Israeli Shekel
- TRY (₺) - Turkish Lira
- PHP (₱) - Philippine Peso
- MYR (RM) - Malaysian Ringgit
- IDR (Rp) - Indonesian Rupiah
- VND (₫) - Vietnamese Dong
- THB (฿) - Thai Baht
- NGN (₦) - Nigerian Naira
- GHS (₵) - Ghanaian Cedi

**Functions**:
- `getCurrencySymbol()` - Async fetch from Hive
- `getCurrencyCode()` - Async fetch from Hive
- `setCurrency()` - Save to Hive
- `getCurrencySymbolSync()` - Sync read from open box

---

## 10. Animations & Visual Effects

### 10.1 Entry Animations
- **Fade In**: Opacity 0 → 1 (0-50% of duration)
- **Scale In**: 0.85/0.6 → 1.0 (0-60% of duration)
- **Slide Up**: Offset(0, 30) → Offset.zero (20-70% of duration)
- **Easing**: easeOut, easeOutBack, easeOutCubic

### 10.2 Interactive Animations
- **Shake Effect**: Wrong PIN horizontal shake (elasticIn curve)
- **Dot Animation**: PIN entry feedback (200ms duration)
- **Pulse Effect**: Loading dots scale oscillation

### 10.3 Background Animations
- **Floating Circles**: Sine wave vertical motion
- **Particle System**: 12 floating particles with random properties
- **Decorative Dots**: Circular arrangement with delayed fade-in

### 10.4 Transition Effects
- **Screen Transitions**: Fade + Scale (1.1 → 1.0)
- **Duration**: 500-600ms
- **Curve**: easeOutCubic

---

## 11. State Management

### 11.1 Approach
- **Local State**: StatefulWidget for screen-specific state
- **Reactive UI**: ValueListenableBuilder for Hive data
- **Provider Pattern**: Not used (direct Hive integration)

### 11.2 Data Flow
```
Hive Box (expenses)
    ↓
ValueListenableBuilder
    ↓
UI Rebuild
```

---

## 12. Architecture & Project Structure

```
lib/
├── main.dart                     # App entry point
├── todo_model.dart              # Legacy model wrapper
├── model/
│   ├── expense_model.dart       # Expense Hive model
│   ├── expense_model.g.dart     # Generated adapter
│   ├── expense_tile.dart        # List item widget
│   ├── expense_summary_card.dart # Dashboard widget
│   └── todo_model.dart          # Todo Hive model
├── screen/
│   ├── splash_screen.dart       # Loading screen
│   ├── lock_screen.dart         # PIN/biometric auth
│   ├── home_screen.dart         # Main dashboard
│   ├── form_screen.dart         # Add expense form
│   ├── edit_expense_screen.dart # Edit expense form
│   ├── connect_screen.dart      # Contact management
│   ├── contact_detail_screen.dart # Contact expenses
│   └── settings_screen.dart     # App settings
├── widget/
│   ├── app_nav_bar.dart         # Bottom navigation
│   └── glass_widgets.dart       # Glassmorphism components
└── utils/
    ├── app_colors.dart          # Colors & theme
    └── currency_helper.dart     # Currency utilities
```

---

## 13. Key Technical Concepts

### 13.1 Hive Database
- **NoSQL** local database
- **Type-safe** with adapters
- **Reactive** with ValueListenable
- **Fast** key-value storage

### 13.2 Glassmorphism Design
- **BackdropFilter** for blur effect
- **Alpha transparency** for frosted look
- **Border highlights** for glass edges
- **Gradients** for depth

### 13.3 Material 3
- Modern Material Design system
- Dynamic color support
- Updated component styles
- Accessibility improvements

### 13.4 Local Authentication
- **local_auth** package for biometrics
- Fallback to PIN
- Platform-specific biometrics (Touch ID, Face ID, fingerprint)

### 13.5 Contact Integration
- **flutter_contacts** for device contacts
- Permission handling
- Contact prefilling for expenses

### 13.6 Type-Based Coloring
- **Lend**: Soft green (#A8E6CF) for expense tiles, Dark green (#2E7D32) for summary card
- **Borrow**: Soft red (#FFB4B4) for expense tiles, Dark red (#C62828) for summary card
- Summary card uses darker shades for better visual hierarchy

---

## 14. User Experience Features

### 14.1 Onboarding
- First-launch PIN setup flow
- Clear instructions and validation
- Visual feedback for PIN entry

### 14.2 Error Handling
- Wrong PIN shake animation
- Validation messages (SnackBar)
- Error states for failed operations

### 14.3 Micro-interactions
- Haptic feedback on PIN entry
- Button press animations
- Swipe gesture feedback
- Loading indicators

### 14.4 Accessibility
- Clear typography hierarchy
- High contrast text
- Large touch targets (76px number pad)
- Semantic icons with labels

---

## 15. Future Enhancement Opportunities

### 15.1 Features
- [ ] Export expenses to CSV/PDF
- [ ] Recurring expense automation
- [ ] Expense categories with icons/colors
- [ ] Charts and analytics (pie charts, trends)
- [ ] Budget limits and alerts
- [ ] Multi-currency conversion
- [ ] Cloud sync across devices
- [ ] Expense notifications/reminders
- [ ] Search and filter expenses
- [ ] Dark mode support

### 15.2 Technical Improvements
- [ ] Bloc/Cubit state management
- [ ] Unit and widget tests
- [ ] CI/CD pipeline
- [ ] Analytics integration
- [ ] Crash reporting (Firebase Crashlytics)
- [ ] Performance optimization
- [ ] Accessibility audit

---

## 16. Performance Considerations

### 16.1 Optimizations
- **ListView.builder** for large expense lists
- **ValueListenableBuilder** for targeted Hive updates
- **Lazy loading** for contacts
- **Animation controllers** properly disposed
- **Const constructors** where possible

### 16.2 Storage
- Hive for offline-first data
- Minimal storage footprint
- Efficient type adapters

---

## 17. Security Considerations

### 17.1 Data Protection
- PIN stored locally in Hive
- Biometric auth optional
- No sensitive data in logs
- Input validation for all fields

### 17.2 Privacy
- Local-only storage (no cloud by default)
- Permission-based contact access
- User-controlled data

---

## 18. Testing Strategy

### 18.1 Current Coverage
- Development testing via Flutter's hot reload
- Manual UI testing

### 18.2 Recommended Tests
- Widget tests for screens
- Unit tests for models
- Integration tests for flows
- Platform-specific tests (Android/iOS)

---

## 19. Deployment Information

### 19.1 Platform Support
- **Android**: Full support (API 21+)
- **iOS**: Full support (iOS 12+)
- **Web**: Experimental
- **Desktop**: Experimental

### 19.2 Permissions Required
- **Android**:
  - `android.permission.USE_BIOMETRIC`
  - `android.permission.READ_CONTACTS` (for Connect feature)
- **iOS**:
  - `NSFaceIDUsageDescription`
  - `NSContactsUsageDescription`

---

## 20. Code Quality

### 20.1 Standards
- **Flutter Lints**: Configured via analysis_options.yaml
- **Material 3**: Modern design system
- **Type Safety**: Strong typing throughout
- **Null Safety**: Full null safety enabled

### 20.2 Best Practices
- Separation of concerns (models, screens, widgets, utils)
- Reusable widget components
- Consistent naming conventions
- Commented complex logic
- Proper state management

---

## 21. Development Environment

### 21.1 SDK Requirements
- Flutter SDK: ^3.12.2
- Dart: 3.x

### 21.2 IDE Support
- Visual Studio Code (Primary)
- Android Studio
- IntelliJ IDEA

---

## 22. Conclusion

The Expense Manager app is a well-architected Flutter application that combines:
- **Modern UI/UX** with glassmorphism design
- **Robust security** with PIN and biometric authentication
- **Practical functionality** for expense tracking
- **Scalable architecture** for future enhancements
- **Cross-platform compatibility** for wide reach

The app successfully addresses the core need of tracking lent and borrowed money while providing an enjoyable, secure user experience through thoughtful animations, intuitive navigation, and a cohesive visual design system.

---

## 23. Project Metadata

- **Package Name**: `to_do`
- **Description**: A new Flutter project
- **Version**: 1.0.0+1
- **License**: Private (not published to pub.dev)
- **Development Status**: Active
- **Last Updated**: July 2026

---

*Report generated for comprehensive project understanding and AI-assisted development.*