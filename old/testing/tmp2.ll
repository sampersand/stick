target triple = "arm64-apple-macosx12.0.0"

@lc_globals = common global [100000 x i64] zeroinitializer, align 8
@lc_idx = local_unnamed_addr global i64* getelementptr inbounds ([100000 x i64], [100000 x i64]* @lc_globals, i64 0, i64 0), align 8
@.lc_to_str_str = private unnamed_addr constant [5 x i8] c"%lld ", align 1
@lc_to_str.ptrbuf = internal global [40 x i8] zeroinitializer, align 1

declare noundef i32 @puts(i8* nocapture noundef readonly) local_unnamed_addr #2
declare noundef i64 @strtoll(i8* nocapture noundef readonly, i8**, i32) ; should really be `, i8**`
declare noalias i8* @strdup(i8* nocapture readonly) local_unnamed_addr #1
declare noundef i32 @snprintf(i8* noalias nocapture noundef writeonly, i64 noundef, i8* nocapture noundef readonly, ...) local_unnamed_addr #5


define noalias i8* @lc_to_str(i64 %0)  {
  %2 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* nonnull dereferenceable(1) getelementptr inbounds ([40 x i8], [40 x i8]* @lc_to_str.ptrbuf, i64 0, i64 0), i64 40, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.lc_to_str_str, i64 0, i64 0), i64 %0)
  %3 = tail call i8* @strdup(i8* getelementptr inbounds ([40 x i8], [40 x i8]* @lc_to_str.ptrbuf, i64 0, i64 0))
  ret i8* %3
}

define i64 @lc_to_int(i8* %0) {
  %2 = call i64 @strtoll(i8* nocapture %0, i8** null, i32 10)
  ret i64 %2
}

define void @push(i64 %0) {
  %2 = load i64*, i64** @lc_idx
  %3 = getelementptr inbounds i64, i64* %2, i64 1
  store i64* %3, i64** @lc_idx
  store i64 %0, i64* %2
  ret void
}

define i64 @pop() {
  %1 = load i64*, i64** @lc_idx
  %2 = getelementptr inbounds i64, i64* %1, i64 -1
  store i64* %2, i64** @lc_idx
  %3 = load i64, i64* %2
  ret i64 %3
}

@.lc_const_0 = private unnamed_addr constant [2 x i8] c"3 ", align 1
@.lc_const_1 = private unnamed_addr constant [2 x i8] c"4 ", align 1

; define void @_lc_user_main() {
define void @main() {
  %1 = getelementptr inbounds [2 x i8], [2 x i8]* @.lc_const_0, i64 0, i64 0
  %2 = ptrtoint i8* %1 to i64
  call void @push(i64 %2)
  %3 = getelementptr inbounds [2 x i8], [2 x i8]* @.lc_const_1, i64 0, i64 0
  %4 = ptrtoint i8* %3 to i64
  call void @push(i64 %4)
  %5 = getelementptr inbounds [2 x i8], [2 x i8]* @.lc_const_1, i64 0, i64 0
  %6 = ptrtoint i8* %5 to i64
  call void @push(i64 %6)
  %7 = call i64 @pop()
  %8 = inttoptr i64 %7 to i8*
  %9 = call i64 @lc_to_int(i8* %8)
  %10 = call i64 @pop()
  %11 = inttoptr i64 %10 to i8*
  %12 = call i64 @lc_to_int(i8* %11)
  %13 = add i64 %9, %12
  %14 = call i8* @lc_to_str(i64 %13)
  %15 = ptrtoint i8* %14 to i64
  call void @push(i64 %15)
  %16 = call i64 @pop()
  %17 = inttoptr i64 %16 to i8*
  %18 = call i32 @puts(i8* %17)
  ret void
}