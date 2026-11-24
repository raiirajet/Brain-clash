import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class ProfileSnapshot {
 final int revision;
 final String active;
 final Map<String,dynamic> profiles;
 const ProfileSnapshot(this.revision,this.active,this.profiles);
 Map<String,dynamic> toJson()=>{'revision':revision,'active':active,'profiles':profiles};
 factory ProfileSnapshot.fromJson(Map data)=>ProfileSnapshot(data['revision'] as int? ??0,data['active'] as String? ??'Gast',Map<String,dynamic>.from(data['profiles'] as Map));
}
class ProfileStore {
 final Database db;
 ProfileStore(this.db);
 static Future<ProfileStore> open({String? databasePath})async{
  final root=await getDatabasesPath();
  final db=await openDatabase(databasePath??'$root/brain_clash_v1.db',version:1,onConfigure:(db)=>db.execute('PRAGMA foreign_keys=ON'),onCreate:(db,version)async{
   await db.execute('CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
   await db.execute('CREATE TABLE profiles (name TEXT PRIMARY KEY, payload TEXT NOT NULL)');
   await db.execute('CREATE TABLE game_sessions (id TEXT PRIMARY KEY, profile TEXT NOT NULL REFERENCES profiles(name) ON DELETE CASCADE, date TEXT, game TEXT, correct INTEGER, total INTEGER, points INTEGER)');
   await db.execute('CREATE TABLE attempts (session TEXT NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE, position INTEGER NOT NULL, prompt TEXT, solution TEXT, response TEXT, correct INTEGER, elapsed_ms INTEGER, PRIMARY KEY(session,position))');
  });
  return ProfileStore(db);
 }
 Future<ProfileSnapshot?> read()async{
  return db.transaction((txn)async{
   final meta=await txn.query('meta');
   if(meta.isEmpty)return null;
   final values={for(final row in meta)row['key']:row['value']};
   final rows=await txn.query('profiles');
   final profiles=<String,dynamic>{for(final row in rows)row['name'] as String:jsonDecode(row['payload'] as String)};
   return ProfileSnapshot(int.parse(values['revision'] as String),values['active'] as String,profiles);
  });
 }
 Future<void> write(ProfileSnapshot snapshot)async{
  await db.transaction((txn)async{
   final batch=txn.batch();
   // Whole-profile snapshot is atomic. History is capped in Progress.
   batch.delete('profiles');
   for(final entry in snapshot.profiles.entries){
    batch.insert('profiles',{'name':entry.key,'payload':jsonEncode(entry.value)});
    final profile=entry.value as Map;
    final history=profile['history'] as List? ??[];
    for(var i=0;i<history.length;i++){
     final row=history[i] as Map,id='${entry.key}:$i';
     batch.insert('game_sessions',{'id':id,'profile':entry.key,'date':row['date'],'game':row['game']??row['world'],'correct':row['right'],'total':row['total'],'points':row['points']});
     final attempts=row['attempts'] as List? ??[];
     for(var j=0;j<attempts.length;j++){
      final a=attempts[j] as Map;
      batch.insert('attempts',{'session':id,'position':j,'prompt':a['prompt'],'solution':a['solution'],'response':a['response'],'correct':a['correct']==true?1:0,'elapsed_ms':a['ms']});
     }
    }
   }
   batch.insert('meta',{'key':'revision','value':'${snapshot.revision}'},conflictAlgorithm:ConflictAlgorithm.replace);
   batch.insert('meta',{'key':'active','value':snapshot.active},conflictAlgorithm:ConflictAlgorithm.replace);
   await batch.commit(noResult:true);
  });
 }
}
