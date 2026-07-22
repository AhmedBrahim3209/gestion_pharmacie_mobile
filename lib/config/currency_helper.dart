class AppCurrency {
  static const String symbol = 'MRU';
  static const String name = 'Ougiya';

  static String format(dynamic amount) {
    if (amount == null) return '0 $symbol';
    final num val = amount is num ? amount : (double.tryParse(amount.toString()) ?? 0);
    if (val == val.roundToDouble()) {
      return '${val.toInt()} $symbol';
    }
    return '${val.toStringAsFixed(2)} $symbol';
  }
}
