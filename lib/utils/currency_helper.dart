import 'package:intl/intl.dart';

/// List of supported currencies with their symbols and names.
class CurrencyInfo {
  final String symbol;
  final String name;
  final String code;

  const CurrencyInfo({
    required this.symbol,
    required this.name,
    required this.code,
  });
}

const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo(symbol: '\$', name: 'US Dollar', code: 'USD'),
  CurrencyInfo(symbol: '€', name: 'Euro', code: 'EUR'),
  CurrencyInfo(symbol: '£', name: 'British Pound', code: 'GBP'),
  CurrencyInfo(symbol: '¥', name: 'Japanese Yen', code: 'JPY'),
  CurrencyInfo(symbol: '₹', name: 'Indian Rupee', code: 'INR'),
  CurrencyInfo(symbol: '₩', name: 'South Korean Won', code: 'KRW'),
  CurrencyInfo(symbol: '₽', name: 'Russian Ruble', code: 'RUB'),
  CurrencyInfo(symbol: 'R\$', name: 'Brazilian Real', code: 'BRL'),
  CurrencyInfo(symbol: 'A\$', name: 'Australian Dollar', code: 'AUD'),
  CurrencyInfo(symbol: 'C\$', name: 'Canadian Dollar', code: 'CAD'),
  CurrencyInfo(symbol: 'CHF', name: 'Swiss Franc', code: 'CHF'),
  CurrencyInfo(symbol: '₪', name: 'Israeli Shekel', code: 'ILS'),
  CurrencyInfo(symbol: '₺', name: 'Turkish Lira', code: 'TRY'),
  CurrencyInfo(symbol: '₱', name: 'Philippine Peso', code: 'PHP'),
  CurrencyInfo(symbol: 'RM', name: 'Malaysian Ringgit', code: 'MYR'),
  CurrencyInfo(symbol: 'Rp', name: 'Indonesian Rupiah', code: 'IDR'),
  CurrencyInfo(symbol: '₫', name: 'Vietnamese Dong', code: 'VND'),
  CurrencyInfo(symbol: '฿', name: 'Thai Baht', code: 'THB'),
  CurrencyInfo(symbol: '₦', name: 'Nigerian Naira', code: 'NGN'),
  CurrencyInfo(symbol: '₵', name: 'Ghanaian Cedi', code: 'GHS'),
];

/// Formats [amount] with the given [symbol] using locale-aware thousand separators and 2 decimal places.
String formatCurrency(double amount, String symbol) {
  final format = _currencyFormats.putIfAbsent(
    symbol,
    () => NumberFormat.currency(symbol: symbol, decimalDigits: 2),
  );
  return format.format(amount);
}

final Map<String, NumberFormat> _currencyFormats = {};
final DateFormat _displayDateFormat = DateFormat.yMMMd();

/// Formats a date string (ISO 8601) to a user-friendly format like "Jul 15, 2026".
String formatDate(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return isoDate;
  return _displayDateFormat.format(date);
}
