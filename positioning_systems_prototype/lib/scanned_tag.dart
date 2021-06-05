enum TagType { PATIENT, ENTITY }

class ScannedTag {
  final TagType type;
  late final DateTime time;
  final String id;

  ScannedTag({required this.type, required this.id}) {
    time = DateTime.now();
  }

  @override
  String toString() {
    final typeString = (type == TagType.PATIENT) ? "patient" : "entity";
    return typeString + " - $id";
  }
}
