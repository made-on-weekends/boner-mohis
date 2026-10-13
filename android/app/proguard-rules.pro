# WorkManager uses Room, which generates DB implementation classes
# (e.g. WorkDatabase_Impl) instantiated via reflection at runtime.
# R8 strips/renames these without a keep rule, crashing app startup
# with NoSuchMethodException on androidx.work.impl.WorkDatabase_Impl.<init>.
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep @androidx.room.Database class * { *; }
