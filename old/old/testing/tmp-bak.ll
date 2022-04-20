; ModuleID = 'tmp.c'
source_filename = "tmp.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx12.0.0"

@globals = common global [100000 x i64] zeroinitializer, align 8
@idx = local_unnamed_addr global i64* getelementptr inbounds ([100000 x i64], [100000 x i64]* @globals, i64 0, i64 0), align 8
; @.str = private unnamed_addr constant [6 x i8] c"%lld\0A\00", align 1
@.str = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@.bar = private unnamed_addr constant [5 x i8] c"lol!\00", align 1

; Function Attrs: nofree norecurse nounwind ssp uwtable willreturn
define void @push(i64 %0) {
  %2 = load i64*, i64** @idx
  %3 = getelementptr inbounds i64, i64* %2, i64 1
  store i64* %3, i64** @idx
  store i64 %0, i64* %2
  ret void
}

; Function Attrs: nofree norecurse nounwind ssp uwtable willreturn
define i64 @pop() {
  %1 = load i64*, i64** @idx
  %2 = getelementptr inbounds i64, i64* %1, i64 -1
  store i64* %2, i64** @idx
  %3 = load i64, i64* %2
  ret i64 %3
}

; Function Attrs: nofree norecurse nounwind ssp uwtable willreturn
define i64 @add() {
  %1 = load i64*, i64** @idx
  %2 = getelementptr inbounds i64, i64* %1, i64 -1
  %3 = load i64, i64* %2
  %4 = getelementptr inbounds i64, i64* %1, i64 -2
  store i64* %4, i64** @idx
  %5 = load i64, i64* %4
  %6 = add nsw i64 %5, %3
  ret i64 %6
}


; Function Attrs: noinline nounwind optnone ssp uwtable
define i32 @main() #0 {
  call void @push(i64 4)
  call void @push(i64 45)
  %1 = call i64 @add()
  ; %2 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str, i64 0, i64 0), i64 %1)

  %2 = getelementptr [5 x i8], [5 x i8] * @.bar, i64 0, i64 0 ;i8*) @.bar
  %3 = call i32 (i8*, ...) @printf(
    i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0),
    i8* %2
  )
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(i8* nocapture noundef readonly, ...) local_unnamed_addr #2
