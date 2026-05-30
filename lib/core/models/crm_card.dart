
/// Stub for CrmCard (from core framework)
class CrmCard {
  final String userID;
  final Map<String, dynamic> data;

  CrmCard({
    required this.userID,
    required this.data,
  });

  factory CrmCard.empty({required String userID}) => CrmCard(
    userID: userID,
    data: {},
  );
}
