
# JSON Store

A simple, file-based NoSQL database for Dart applications, offering a FireStore-like API for persistent data storage using JSON files.

## Features

* **FireStore-like API**: Familiar methods for collections, documents, and snapshots.
* **Persistent Storage**: Data is stored in a single JSON file on the device.
* **Singleton Instance**: Ensures only one instance of the database is running at a time.
* **Automatic ID Generation**: Easily add new documents with unique IDs.
* **Merging and Overwriting**: Choose to merge data into existing documents or overwrite them completely.

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  json_store: ^1.0.0 # Use the latest version
  path_provider: ^2.0.0 # Required for getting application documents directory
  uuid: ^4.0.0 # Required for generating unique IDs
```

Then, run `dart pub get` in your project.

## How to Use

### Getting the Instance

First, get the singleton instance of `JsonStore`:

```dart
import 'package:json_store/json_store.dart';

Future<void> main() async {
  final jsonStore = await JsonStore.instance();
  // Your database operations go here
}
```

### Adding Data

You can add documents to a collection. If you don't specify an ID, a new one will be generated automatically.

```dart
// Add a new document to the 'users' collection with an auto-generated ID
final newUserRef = await jsonStore.collection('users').add({
  'name': 'Alice',
  'age': 30,
});
print('Added new user with ID: ${newUserRef.id}');

// Set a document with a specific ID (overwrites if exists)
await jsonStore.collection('products').doc('product123').set({
  'name': 'Laptop',
  'price': 1200,
});
```

### Reading Data

Retrieve documents by their ID or fetch an entire collection.

```dart
// Get a single document
final userSnapshot = await jsonStore.collection('users').doc(newUserRef.id).get();
if (userSnapshot.exists) {
  print('User data: ${userSnapshot.data}');
} else {
  print('User not found.');
}

// Get all documents in a collection
final querySnapshot = await jsonStore.collection('products').get();
for (final doc in querySnapshot.docs) {
  print('Product ID: ${doc.id}, Data: ${doc.data}');
}
```

### Updating Data

You can update existing documents. Use `update` to merge new data, or `set` to overwrite.

```dart
// Update a document (merges data)
await jsonStore.collection('users').doc(newUserRef.id).update({
  'age': 31,
  'city': 'New York',
});

// Overwrite a document (removes old fields not specified)
await jsonStore.collection('products').doc('product123').set({
  'name': 'Gaming Laptop',
  'price': 1500,
  'inStock': true,
});
```

### Deleting Data

Remove documents from a collection.

```dart
// Delete a document
await jsonStore.collection('users').doc(newUserRef.id).delete();
print('User ${newUserRef.id} deleted.');
```

## API Reference

### `JsonStore`

* `static Future<JsonStore> instance()`: Returns the singleton instance of `JsonStore`.
* `CollectionReference collection(String path)`: Returns a `CollectionReference` for the specified collection `path`.

### `CollectionReference`

* `DocumentReference doc(String id)`: Returns a `DocumentReference` for the document with the given `id`.
* `Future<DocumentReference> add(Map<String, dynamic> data)`: Adds a new document to this collection with the given `data`. A new document ID is automatically generated.
* `Future<QuerySnapshot> get()`: Reads all documents in this collection.

### `DocumentReference`

* `Future<void> set(Map<String, dynamic> data)`: Sets the data for the document, overwriting any existing data.
* `Future<void> update(Map<String, dynamic> data)`: Updates fields in the document. Fields not specified are not changed.
* `Future<DocumentSnapshot> get()`: Reads the document referred to by this `DocumentReference`.
* `Future<void> delete()`: Deletes the document referred to by this `DocumentReference`.

### `DocumentSnapshot`

* `final String id`: The ID of the document.
* `final Map<String, dynamic>? data`: The data of the document.
* `final bool exists`: True if the document exists, false otherwise.
* `Map<String, dynamic>? get()`: Returns the data of the document.

### `QuerySnapshot`

* `final List<DocumentSnapshot> docs`: A list of `DocumentSnapshot` objects.
* `List<DocumentSnapshot> get()`: Returns a list of document snapshots.
