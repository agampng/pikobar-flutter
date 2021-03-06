import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pikobar_flutter/constants/collections.dart';

class DocumentsRepository {
  final documentsCollection = Firestore.instance.collection(kDocuments);

  Stream<List<DocumentSnapshot>> getDocuments({int limit}) {
    Query documentsQuery =
        documentsCollection.orderBy('published_at', descending: true);

    if (limit != null) {
      documentsQuery = documentsQuery.limit(limit);
    }

    return documentsQuery.snapshots().map((QuerySnapshot snapshot) =>
        snapshot.documents.map((doc) => doc).toList());
  }
}
