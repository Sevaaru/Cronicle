// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$googleBooksApiHash() => r'c99804a445c1068bd4afec2c44c874fbbe7647b1';

/// See also [googleBooksApi].
@ProviderFor(googleBooksApi)
final googleBooksApiProvider = Provider<GoogleBooksApiDatasource>.internal(
  googleBooksApi,
  name: r'googleBooksApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$googleBooksApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GoogleBooksApiRef = ProviderRef<GoogleBooksApiDatasource>;
String _$bookSearchHash() => r'16592cee32cdf608296f375035d17e025f3b9907';

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

String _$bookSubjectHash() => r'367bf95d8e79048c067c65cd1c8d83bfa4e46cdd';

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
class BookSubjectProvider extends FutureProvider<List<Map<String, dynamic>>> {
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
  FutureProviderElement<List<Map<String, dynamic>>> createElement() {
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
mixin BookSubjectRef on FutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `subject` of this provider.
  String get subject;
}

class _BookSubjectProviderElement
    extends FutureProviderElement<List<Map<String, dynamic>>>
    with BookSubjectRef {
  _BookSubjectProviderElement(super.provider);

  @override
  String get subject => (origin as BookSubjectProvider).subject;
}

String _$bookWorkHash() => r'1ca009f8cc64ef545a5bcd680053eaedde1d2e39';

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
class BookWorkProvider extends FutureProvider<Map<String, dynamic>> {
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
  FutureProviderElement<Map<String, dynamic>> createElement() {
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
mixin BookWorkRef on FutureProviderRef<Map<String, dynamic>> {
  /// The parameter `workKey` of this provider.
  String get workKey;
}

class _BookWorkProviderElement
    extends FutureProviderElement<Map<String, dynamic>>
    with BookWorkRef {
  _BookWorkProviderElement(super.provider);

  @override
  String get workKey => (origin as BookWorkProvider).workKey;
}

String _$bookSubjectBrowseHash() => r'da917285b7878289eadc2ce7a0e4f8cb2ae26cdf';

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

String _$bookWorkEditionsHash() => r'3911363667adbd32cafd96e069ce8bf1b2f037f0';

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

String _$bookEditionHash() => r'281800e9f317556149b5c3cbceb0af6b00b912af';

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

String _$booksHomeFeedHash() => r'2c6fc9dfd8253a476618cbe76fc607c926be2a9e';

/// See also [BooksHomeFeed].
@ProviderFor(BooksHomeFeed)
final booksHomeFeedProvider =
    AsyncNotifierProvider<BooksHomeFeed, BooksHomeFeedData>.internal(
      BooksHomeFeed.new,
      name: r'booksHomeFeedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$booksHomeFeedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BooksHomeFeed = AsyncNotifier<BooksHomeFeedData>;
String _$bookTrendingHash() => r'b8a320c5fa5ad7517e5db90fc2f40a9a6aeaeaf2';

/// See also [BookTrending].
@ProviderFor(BookTrending)
final bookTrendingProvider =
    AsyncNotifierProvider<BookTrending, List<Map<String, dynamic>>>.internal(
      BookTrending.new,
      name: r'bookTrendingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bookTrendingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BookTrending = AsyncNotifier<List<Map<String, dynamic>>>;
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
