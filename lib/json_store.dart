/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'src/json_store_base.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // Add uuid to your pubspec.yaml: dependencies: uuid: ^4.0.0

/// Represents a snapshot of a document, similar to FireStore's DocumentSnapshot.
class DocumentSnapshot {
  final String id;
  final Map<String, dynamic>? data;
  final bool exists;

  DocumentSnapshot(this.id, this.data) : exists = data != null;

  /// Returns the data of the document.
  Map<String, dynamic>? get() => data;
}

/// Represents a snapshot of a query result, similar to FireStore's QuerySnapshot.
class QuerySnapshot {
  final List<DocumentSnapshot> docs;

  QuerySnapshot(this.docs);

  /// Returns a list of document snapshots.
  List<DocumentSnapshot> get() => docs;
}

/// Represents a reference to a specific document in a collection.
class DocumentReference {
  final String _collectionPath;
  final String id;
  final JsonStore _jsonStore;

  DocumentReference(this._collectionPath, this.id, this._jsonStore);

  /// Sets the data for the document, overwriting any existing data.
  Future<void> set(Map<String, dynamic> data) async {
    await _jsonStore._updateDocument(_collectionPath, id, data, merge: false);
  }

  /// Updates fields in the document. Fields not specified are not changed.
  Future<void> update(Map<String, dynamic> data) async {
    await _jsonStore._updateDocument(_collectionPath, id, data, merge: true);
  }

  /// Reads the document referred to by this [DocumentReference].
  Future<DocumentSnapshot> get() async {
    final docData = await _jsonStore._getDocument(_collectionPath, id);
    return DocumentSnapshot(id, docData);
  }

  /// Deletes the document referred to by this [DocumentReference].
  Future<void> delete() async {
    await _jsonStore._deleteDocument(_collectionPath, id);
  }
}

/// Represents a reference to a collection of documents.
class CollectionReference {
  final String path;
  final JsonStore _jsonStore;
  final Uuid _uuid = Uuid();

  CollectionReference(this.path, this._jsonStore);

  /// Gets a [DocumentReference] for the document with the given [id].
  DocumentReference doc(String id) {
    return DocumentReference(path, id, _jsonStore);
  }

  /// Adds a new document to this collection with the given [data].
  /// A new document ID is automatically generated.
  Future<DocumentReference> add(Map<String, dynamic> data) async {
    final newDocId = _uuid.v4();
    await _jsonStore._updateDocument(path, newDocId, data, merge: false);
    return DocumentReference(path, newDocId, _jsonStore);
  }

  /// Reads all documents in this collection.
  Future<QuerySnapshot> get() async {
    final collectionData = await _jsonStore._getCollection(path);
    final docs =
        collectionData.entries
            .map((entry) => DocumentSnapshot(entry.key, entry.value))
            .toList();
    return QuerySnapshot(docs);
  }
}

/// A simple class that mimics Firebase JsonStore's style,
/// but reads/writes to a JSON file.
class JsonStore {
  final File _file;
  Map<String, Map<String, Map<String, dynamic>>> _data = {};

  // Private constructor
  JsonStore._internal(this._file);

  // Singleton instance
  static JsonStore? _instance;

  /// Returns the singleton instance of JsonStore.
  /// Initializes it if it hasn't been initialized yet.
  static Future<JsonStore> instance() async {
    if (_instance == null) {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/jsonstore_db.json';
      final file = File(filePath);
      _instance = JsonStore._internal(file);
      await _instance!._loadData(); // Load data during initialization
    }
    return _instance!;
  }

  /// Private method to load data from the file.
  Future<void> _loadData() async {
    if (await _file.exists()) {
      try {
        final content = await _file.readAsString();
        if (content.isNotEmpty) {
          _data = (jsonDecode(content) as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              key,
              (value as Map<String, dynamic>).map(
                (docKey, docValue) =>
                    MapEntry(docKey, docValue as Map<String, dynamic>),
              ),
            ),
          );
        }
      } catch (e) {
        // If file is corrupted, start with empty data
        _data = {};
        throw ('Error loading data from file: $e');
      }
    } else {
      // Create the file if it doesn't exist
      await _file.create(recursive: true);
    }
  }

  /// Returns a [CollectionReference] for the specified collection [path].
  CollectionReference collection(String path) {
    return CollectionReference(path, this);
  }

  /// Internal method to get a document's data.
  Future<Map<String, dynamic>?> _getDocument(
    String collectionPath,
    String docId,
  ) async {
    // Data is loaded once during instance creation.
    return _data[collectionPath]?[docId];
  }

  /// Internal method to get all documents in a collection.
  Future<Map<String, Map<String, dynamic>>> _getCollection(
    String collectionPath,
  ) async {
    // Data is loaded once during instance creation.
    return _data[collectionPath] ?? {};
  }

  /// Internal method to update or set a document.
  Future<void> _updateDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data, {
    required bool merge,
  }) async {
    _data.putIfAbsent(collectionPath, () => {});
    if (merge && _data[collectionPath]!.containsKey(docId)) {
      _data[collectionPath]![docId]!.addAll(data);
    } else {
      _data[collectionPath]![docId] = data;
    }
    await _writeData();
  }

  /// Internal method to delete a document.
  Future<void> _deleteDocument(String collectionPath, String docId) async {
    if (_data.containsKey(collectionPath)) {
      _data[collectionPath]!.remove(docId);
      if (_data[collectionPath]!.isEmpty) {
        _data.remove(collectionPath); // Remove collection if it's empty
      }
      await _writeData();
    }
  }

  /// Writes the current in-memory data to the JSON file.
  Future<void> _writeData() async {
    try {
      final jsonString = jsonEncode(_data);
      await _file.writeAsString(jsonString);
    } catch (e) {
      throw ('Error writing data to file: $e');
    }
  }
}
