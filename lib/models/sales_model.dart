class OutletInfo {
  final String id;
  final String name;
  final String shortName;
  final String location;
  final String posTerminalId;
  final bool isOnline;

  const OutletInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.location,
    required this.posTerminalId,
    this.isOnline = true,
  });
}

class ChannelSales {
  final String title;
  final double amount;
  final int orderCount;
  final String metricLabel;
  final String metricValue;
  final List<OrderItem> recentOrders;

  const ChannelSales({
    required this.title,
    required this.amount,
    required this.orderCount,
    required this.metricLabel,
    required this.metricValue,
    required this.recentOrders,
  });
}

class OrderItem {
  final String orderId;
  final String time;
  final String itemsSummary;
  final double total;
  final String status;
  final String paymentMode;

  const OrderItem({
    required this.orderId,
    required this.time,
    required this.itemsSummary,
    required this.total,
    required this.status,
    required this.paymentMode,
  });
}
