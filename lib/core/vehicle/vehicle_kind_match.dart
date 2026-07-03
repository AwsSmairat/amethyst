/// تصنيف مبيعات المركبات حسب رقم المركبة (باص / بينقو).
enum VehicleSalesBucket { bus, bingo, other }

VehicleSalesBucket vehicleSalesBucketForNumber(String? vehicleNumber) {
  final String n = (vehicleNumber ?? '').toLowerCase();
  if (n.contains('باص') || n.contains('bus')) {
    return VehicleSalesBucket.bus;
  }
  if (n.contains('بينقو') || n.contains('bingo')) {
    return VehicleSalesBucket.bingo;
  }
  return VehicleSalesBucket.other;
}
