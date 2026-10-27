import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed shared data access. Business modules add their own queries and flows.
/// Inserts never overwrite another record; updates never recreate a deleted one.
class FirestoreRepository<T> {
  final FirebaseFirestore firestore;
  final CollectionReference<T> collection;
  final String Function(T) idOf;
  final Map<String, dynamic> Function(T) encode;

  FirestoreRepository({
    required this.firestore,
    required String path,
    required T Function(String, Map<String, dynamic>) decode,
    required this.encode,
    required this.idOf,
  }) : collection = firestore
           .collection(path)
           .withConverter<T>(
             fromFirestore: (snapshot, _) =>
                 decode(snapshot.id, snapshot.data()!),
             toFirestore: (value, _) => encode(value),
           );

  Future<T?> getById(String id) async =>
      (await collection.doc(id).get()).data();

  Stream<List<T>> watchAll() => collection.snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
  );

  Future<void> create(T value) async {
    final data = encode(value);
    final ref = collection.doc(idOf(value));
    await firestore.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) {
        throw StateError('Mã bản ghi đã tồn tại.');
      }
      transaction.set(firestore.doc(ref.path), data);
    });
  }

  Future<void> update(T value) async {
    final data = encode(value);
    // Firestore update fails with not-found instead of silently inserting.
    await firestore.doc(collection.doc(idOf(value)).path).update(data);
  }
}
