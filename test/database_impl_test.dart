library sembast.database_test;

// basically same as the io runner but with extra output
import 'package:sembast/sembast.dart';
import 'package:sembast/src/database_impl.dart';

import 'test_common.dart';

void main() {
  defineTests(memoryDatabaseContext);
}

void defineTests(DatabaseTestContext ctx) {
  DatabaseFactory factory = ctx.factory;
  String dbPath;

  group('database_impl', () {
    dbPath = ctx.dbPath;

    group('open', () {
      Database db;

      setUp(() {
        return factory.deleteDatabase(dbPath).then((_) {});
      });

      tearDown(() {
        if (db != null) {
          db.close();
        }
      });

      test('open_then_open_no_version', () async {
        SembastDatabase db =
            await factory.openDatabase(dbPath, version: 1) as SembastDatabase;
        return db.reOpen().then((Database db) {
          expect(db.path, dbPath);
          expect(db.version, 1);
          db.close();
        });
      });
    });

    group('onVersionChanged', () {
      Database db;

      setUp(() {
        return factory.deleteDatabase(dbPath).then((_) {});
      });

      tearDown(() {
        if (db != null) {
          db.close();
        }
      });

      test('open_then_open_no_version_or_same_version', () async {
        SembastDatabase db =
            await factory.openDatabase(dbPath, version: 1) as SembastDatabase;
        _onVersionChanged(Database db, int oldVersion, int newVersion) {
          fail("not changed");
        }

        return db
            .reOpen(onVersionChanged: _onVersionChanged)
            .then((Database db) {
          expect(db.path, dbPath);
          expect(db.version, 1);
          db.close();
        }).then((_) {
          return db
              .reOpen(version: 1, onVersionChanged: _onVersionChanged)
              .then((Database db) {
            expect(db.path, dbPath);
            expect(db.version, 1);
            db.close();
          });
        });
      });

      test('open_then_open_new_version', () async {
        SembastDatabase db =
            await factory.openDatabase(dbPath, version: 1) as SembastDatabase;
// save to make sure we've been through
        int _oldVersion;
        int _newVersion;
        _onVersionChanged(Database db, int oldVersion, int newVersion) {
          expect(db.version, oldVersion);
          _oldVersion = oldVersion;
          _newVersion = newVersion;
        }

        return db
            .reOpen(version: 2, onVersionChanged: _onVersionChanged)
            .then((Database db) {
          expect(_oldVersion, 1);
          expect(_newVersion, 2);
          expect(db.path, dbPath);
          expect(db.version, 2);
          db.close();
        });
      });
    });

    group('format', () {
      Database db;

      setUp(() {
        return factory.deleteDatabase(dbPath).then((_) {});
      });

      tearDown(() {
        if (db != null) {
          db.close();
        }
      });

      test('export', () async {
        SembastDatabase db =
            await factory.openDatabase(dbPath) as SembastDatabase;
        expect(
            // ignore: deprecated_member_use
            db.toJson()["exportStat"],
            // ignore: deprecated_member_use
            factory.hasStorage ? isNotNull : isNull);
      });
    });
  });
}