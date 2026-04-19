// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$openLibraryApiHash() => r'2a35033b35e7ab3a48161457a03c3667b8a1aca8';

/// See also [openLibraryApi].
@ProviderFor(openLibraryApi)
final openLibraryApiProvider = Provider<OpenLibraryApiDatasource>.internal(
  openLibraryApi,
  name: r'openLibraryApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$openLibraryApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OpenLibraryApiRef = ProviderRef<OpenLibraryApiDatasource>;
String _$bookSearchHash() => r'750a7a13e70969330c8fcdae6338fe3b9543713e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [bookSearch].
@ProviderFor(bookSearch)
const bookSearchProvider = BookSearchFamily();

/// See also [bookSearch].
class BookSearchFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [bookSearch].
  const BookSearchFamily();

  /// See also [bookSearch].
  BookSearchProvider call(String query) {
    return BookSearchProvider(query);
  }

  @override
  BookSearchProvider getProviderOverride(
    covariant BookSearchProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookSearchProvider';
}

/// See also [bookSearch].
class BookSearchProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [bookSearch].
  BookSearchProvider(String query)
    : this._internal(
        (ref) => bookSearch(ref as BookSearchRef, query),
        from: bookSearchProvider,
        name: r'bookSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookSearchHash,
        dependencies: BookSearchFamily._dependencies,
        allTransitiveDependencies: BookSearchFamily._allTransitiveDependencies,
        query: query,
      );

  BookSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(BookSearchRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookSearchProvider._internal(
        (ref) => create(ref as BookSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _BookSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookSearchRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _BookSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with BookSearchRef {
  _BookSearchProviderElement(super.provider);

  @override
  String get query => (origin as BookSearchProvider).query;
}

String _$bookTrendingHash() => r'8e1c2bc9ecd5016fd0eed3b8d7cc584fbd4197c3';

/// See also [bookTrending].
@ProviderFor(bookTrending)
final bookTrendingProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      bookTrending,
      name: r'bookTrendingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bookTrendingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BookTrendingRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$bookSubjectHash() => r'545f437e5e6b1f9eb0f877f43c7143ef986a17d6';

/// See also [bookSubject].
@ProviderFor(bookSubject)
const bookSubjectProvider = BookSubjectFamily();

/// See also [bookSubject].
class BookSubjectFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [bookSubject].
  const BookSubjectFamily();

  /// See also [bookSubject].
  BookSubjectProvider call(String subject) {
    return BookSubjectProvider(subject);
  }

  @override
  BookSubjectProvider getProviderOverride(
    covariant BookSubjectProvider provider,
  ) {
    return call(provider.subject);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookSubjectProvider';
}

/// See also [bookSubject].
class BookSubjectProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [bookSubject].
  BookSubjectProvider(String subject)
    : this._internal(
        (ref) => bookSubject(ref as BookSubjectRef, subject),
        from: bookSubjectProvider,
        name: r'bookSubjectProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookSubjectHash,
        dependencies: BookSubjectFamily._dependencies,
        allTransitiveDependencies: BookSubjectFamily._allTransitiveDependencies,
        subject: subject,
      );

  BookSubjectProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subject,
  }) : super.internal();

  final String subject;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(BookSubjectRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookSubjectProvider._internal(
        (ref) => create(ref as BookSubjectRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subject: subject,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _BookSubjectProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookSubjectProvider && other.subject == subject;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subject.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookSubjectRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `subject` of this provider.
  String get subject;
}

class _BookSubjectProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with BookSubjectRef {
  _BookSubjectProviderElement(super.provider);

  @override
  String get subject => (origin as BookSubjectProvider).subject;
}

String _$bookWorkHash() => r'b17165aefdf2d01a9cae6fa7f401ef3f64c4a67e';

/// See also [bookWork].
@ProviderFor(bookWork)
const bookWorkProvider = BookWorkFamily();

/// See also [bookWork].
class BookWorkFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [bookWork].
  const BookWorkFamily();

  /// See also [bookWork].
  BookWorkProvider call(String workKey) {
    return BookWorkProvider(workKey);
  }

  @override
  BookWorkProvider getProviderOverride(covariant BookWorkProvider provider) {
    return call(provider.workKey);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookWorkProvider';
}

/// See also [bookWork].
class BookWorkProvider extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [bookWork].
  BookWorkProvider(String workKey)
    : this._internal(
        (ref) => bookWork(ref as BookWorkRef, workKey),
        from: bookWorkProvider,
        name: r'bookWorkProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookWorkHash,
        dependencies: BookWorkFamily._dependencies,
        allTransitiveDependencies: BookWorkFamily._allTransitiveDependencies,
        workKey: workKey,
      );

  BookWorkProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.workKey,
  }) : super.internal();

  final String workKey;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(BookWorkRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookWorkProvider._internal(
        (ref) => create(ref as BookWorkRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        workKey: workKey,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _BookWorkProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookWorkProvider && other.workKey == workKey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, workKey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookWorkRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `workKey` of this provider.
  String get workKey;
}

class _BookWorkProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with BookWorkRef {
  _BookWorkProviderElement(super.provider);

  @override
  String get workKey => (origin as BookWorkProvider).workKey;
}

String _$bookUserReadingLogHash() =>
    r'33da5d3c118bff983ce9db24d1de9d99866f6054';

/// See also [bookUserReadingLog].
@ProviderFor(bookUserReadingLog)
const bookUserReadingLogProvider = BookUserReadingLogFamily();

/// See also [bookUserReadingLog].
class BookUserReadingLogFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [bookUserReadingLog].
  const BookUserReadingLogFamily();

  /// See also [bookUserReadingLog].
  BookUserReadingLogProvider call(String username, String shelf) {
    return BookUserReadingLogProvider(username, shelf);
  }

  @override
  BookUserReadingLogProvider getProviderOverride(
    covariant BookUserReadingLogProvider provider,
  ) {
    return call(provider.username, provider.shelf);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookUserReadingLogProvider';
}

/// See also [bookUserReadingLog].
class BookUserReadingLogProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [bookUserReadingLog].
  BookUserReadingLogProvider(String username, String shelf)
    : this._internal(
        (ref) =>
            bookUserReadingLog(ref as BookUserReadingLogRef, username, shelf),
        from: bookUserReadingLogProvider,
        name: r'bookUserReadingLogProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookUserReadingLogHash,
        dependencies: BookUserReadingLogFamily._dependencies,
        allTransitiveDependencies:
            BookUserReadingLogFamily._allTransitiveDependencies,
        username: username,
        shelf: shelf,
      );

  BookUserReadingLogProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.username,
    required this.shelf,
  }) : super.internal();

  final String username;
  final String shelf;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
      BookUserReadingLogRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookUserReadingLogProvider._internal(
        (ref) => create(ref as BookUserReadingLogRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        username: username,
        shelf: shelf,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _BookUserReadingLogProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookUserReadingLogProvider &&
        other.username == username &&
        other.shelf == shelf;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, username.hashCode);
    hash = _SystemHash.combine(hash, shelf.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookUserReadingLogRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `username` of this provider.
  String get username;

  /// The parameter `shelf` of this provider.
  String get shelf;
}

class _BookUserReadingLogProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with BookUserReadingLogRef {
  _BookUserReadingLogProviderElement(super.provider);

  @override
  String get username => (origin as BookUserReadingLogProvider).username;
  @override
  String get shelf => (origin as BookUserReadingLogProvider).shelf;
}

String _$bookSubjectBrowseHash() => r'a4f200ab599be1ea8cc298c7d5faaeb853d4d081';

/// See also [bookSubjectBrowse].
@ProviderFor(bookSubjectBrowse)
const bookSubjectBrowseProvider = BookSubjectBrowseFamily();

/// See also [bookSubjectBrowse].
class BookSubjectBrowseFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [bookSubjectBrowse].
  const BookSubjectBrowseFamily();

  /// See also [bookSubjectBrowse].
  BookSubjectBrowseProvider call(String subject, {int limit = 50}) {
    return BookSubjectBrowseProvider(subject, limit: limit);
  }

  @override
  BookSubjectBrowseProvider getProviderOverride(
    covariant BookSubjectBrowseProvider provider,
  ) {
    return call(provider.subject, limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookSubjectBrowseProvider';
}

/// See also [bookSubjectBrowse].
class BookSubjectBrowseProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [bookSubjectBrowse].
  BookSubjectBrowseProvider(String subject, {int limit = 50})
    : this._internal(
        (ref) => bookSubjectBrowse(
          ref as BookSubjectBrowseRef,
          subject,
          limit: limit,
        ),
        from: bookSubjectBrowseProvider,
        name: r'bookSubjectBrowseProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookSubjectBrowseHash,
        dependencies: BookSubjectBrowseFamily._dependencies,
        allTransitiveDependencies:
            BookSubjectBrowseFamily._allTransitiveDependencies,
        subject: subject,
        limit: limit,
      );

  BookSubjectBrowseProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subject,
    required this.limit,
  }) : super.internal();

  final String subject;
  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(BookSubjectBrowseRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookSubjectBrowseProvider._internal(
        (ref) => create(ref as BookSubjectBrowseRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subject: subject,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _BookSubjectBrowseProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookSubjectBrowseProvider &&
        other.subject == subject &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subject.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookSubjectBrowseRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `subject` of this provider.
  String get subject;

  /// The parameter `limit` of this provider.
  int get limit;
}

class _BookSubjectBrowseProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with BookSubjectBrowseRef {
  _BookSubjectBrowseProviderElement(super.provider);

  @override
  String get subject => (origin as BookSubjectBrowseProvider).subject;
  @override
  int get limit => (origin as BookSubjectBrowseProvider).limit;
}

String _$bookWorkEditionsHash() => r'd251d282759443848d56d169816c42a8c9ce99bb';

/// See also [bookWorkEditions].
@ProviderFor(bookWorkEditions)
const bookWorkEditionsProvider = BookWorkEditionsFamily();

/// See also [bookWorkEditions].
class BookWorkEditionsFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [bookWorkEditions].
  const BookWorkEditionsFamily();

  /// See also [bookWorkEditions].
  BookWorkEditionsProvider call(String workKey) {
    return BookWorkEditionsProvider(workKey);
  }

  @override
  BookWorkEditionsProvider getProviderOverride(
    covariant BookWorkEditionsProvider provider,
  ) {
    return call(provider.workKey);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookWorkEditionsProvider';
}

/// See also [bookWorkEditions].
class BookWorkEditionsProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [bookWorkEditions].
  BookWorkEditionsProvider(String workKey)
    : this._internal(
        (ref) => bookWorkEditions(ref as BookWorkEditionsRef, workKey),
        from: bookWorkEditionsProvider,
        name: r'bookWorkEditionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookWorkEditionsHash,
        dependencies: BookWorkEditionsFamily._dependencies,
        allTransitiveDependencies:
            BookWorkEditionsFamily._allTransitiveDependencies,
        workKey: workKey,
      );

  BookWorkEditionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.workKey,
  }) : super.internal();

  final String workKey;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(BookWorkEditionsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookWorkEditionsProvider._internal(
        (ref) => create(ref as BookWorkEditionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        workKey: workKey,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _BookWorkEditionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookWorkEditionsProvider && other.workKey == workKey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, workKey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookWorkEditionsRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `workKey` of this provider.
  String get workKey;
}

class _BookWorkEditionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with BookWorkEditionsRef {
  _BookWorkEditionsProviderElement(super.provider);

  @override
  String get workKey => (origin as BookWorkEditionsProvider).workKey;
}

String _$bookEditionHash() => r'3a0b92fe9f2bbcfdcf7a2a6ff47aee7fc286a391';

/// See also [bookEdition].
@ProviderFor(bookEdition)
const bookEditionProvider = BookEditionFamily();

/// See also [bookEdition].
class BookEditionFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [bookEdition].
  const BookEditionFamily();

  /// See also [bookEdition].
  BookEditionProvider call(String editionKey) {
    return BookEditionProvider(editionKey);
  }

  @override
  BookEditionProvider getProviderOverride(
    covariant BookEditionProvider provider,
  ) {
    return call(provider.editionKey);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookEditionProvider';
}

/// See also [bookEdition].
class BookEditionProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [bookEdition].
  BookEditionProvider(String editionKey)
    : this._internal(
        (ref) => bookEdition(ref as BookEditionRef, editionKey),
        from: bookEditionProvider,
        name: r'bookEditionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookEditionHash,
        dependencies: BookEditionFamily._dependencies,
        allTransitiveDependencies: BookEditionFamily._allTransitiveDependencies,
        editionKey: editionKey,
      );

  BookEditionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.editionKey,
  }) : super.internal();

  final String editionKey;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(BookEditionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookEditionProvider._internal(
        (ref) => create(ref as BookEditionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        editionKey: editionKey,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _BookEditionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookEditionProvider && other.editionKey == editionKey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, editionKey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookEditionRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `editionKey` of this provider.
  String get editionKey;
}

class _BookEditionProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with BookEditionRef {
  _BookEditionProviderElement(super.provider);

  @override
  String get editionKey => (origin as BookEditionProvider).editionKey;
}

String _$bookWorkEditionModelsHash() =>
    r'c032947d769e2818ca035fd29ab760c1116751c2';

/// See also [bookWorkEditionModels].
@ProviderFor(bookWorkEditionModels)
const bookWorkEditionModelsProvider = BookWorkEditionModelsFamily();

/// See also [bookWorkEditionModels].
class BookWorkEditionModelsFamily
    extends Family<AsyncValue<List<BookEdition>>> {
  /// See also [bookWorkEditionModels].
  const BookWorkEditionModelsFamily();

  /// See also [bookWorkEditionModels].
  BookWorkEditionModelsProvider call(String workKey) {
    return BookWorkEditionModelsProvider(workKey);
  }

  @override
  BookWorkEditionModelsProvider getProviderOverride(
    covariant BookWorkEditionModelsProvider provider,
  ) {
    return call(provider.workKey);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookWorkEditionModelsProvider';
}

/// See also [bookWorkEditionModels].
class BookWorkEditionModelsProvider
    extends AutoDisposeFutureProvider<List<BookEdition>> {
  /// See also [bookWorkEditionModels].
  BookWorkEditionModelsProvider(String workKey)
    : this._internal(
        (ref) =>
            bookWorkEditionModels(ref as BookWorkEditionModelsRef, workKey),
        from: bookWorkEditionModelsProvider,
        name: r'bookWorkEditionModelsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookWorkEditionModelsHash,
        dependencies: BookWorkEditionModelsFamily._dependencies,
        allTransitiveDependencies:
            BookWorkEditionModelsFamily._allTransitiveDependencies,
        workKey: workKey,
      );

  BookWorkEditionModelsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.workKey,
  }) : super.internal();

  final String workKey;

  @override
  Override overrideWith(
    FutureOr<List<BookEdition>> Function(BookWorkEditionModelsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookWorkEditionModelsProvider._internal(
        (ref) => create(ref as BookWorkEditionModelsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        workKey: workKey,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BookEdition>> createElement() {
    return _BookWorkEditionModelsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookWorkEditionModelsProvider && other.workKey == workKey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, workKey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookWorkEditionModelsRef
    on AutoDisposeFutureProviderRef<List<BookEdition>> {
  /// The parameter `workKey` of this provider.
  String get workKey;
}

class _BookWorkEditionModelsProviderElement
    extends AutoDisposeFutureProviderElement<List<BookEdition>>
    with BookWorkEditionModelsRef {
  _BookWorkEditionModelsProviderElement(super.provider);

  @override
  String get workKey => (origin as BookWorkEditionModelsProvider).workKey;
}

String _$openLibraryUsernameHash() =>
    r'68077f36ef3a6ed3b5325ffd1b072f471637e109';

/// See also [OpenLibraryUsername].
@ProviderFor(OpenLibraryUsername)
final openLibraryUsernameProvider =
    NotifierProvider<OpenLibraryUsername, String?>.internal(
      OpenLibraryUsername.new,
      name: r'openLibraryUsernameProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$openLibraryUsernameHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OpenLibraryUsername = Notifier<String?>;
String _$favoriteBooksHash() => r'812d75a957f75b2b5701c83e9a5fbb6ac17f02b2';

/// See also [FavoriteBooks].
@ProviderFor(FavoriteBooks)
final favoriteBooksProvider =
    NotifierProvider<FavoriteBooks, List<Map<String, dynamic>>>.internal(
      FavoriteBooks.new,
      name: r'favoriteBooksProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoriteBooksHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FavoriteBooks = Notifier<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
