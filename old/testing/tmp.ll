; ModuleID = 'tmp.c'
source_filename = "tmp.c"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx12.0.0"

@toptr.ptrbuf = internal global [40 x i8] zeroinitializer, align 1
@.str = private unnamed_addr constant [5 x i8] c"%lld\00", align 1
@globals = common global [100000 x i64] zeroinitializer, align 8
@idx = local_unnamed_addr global i64* getelementptr inbounds ([100000 x i64], [100000 x i64]* @globals, i64 0, i64 0), align 8
@.str.1 = private unnamed_addr constant [6 x i8] c"%lld\0A\00", align 1

; Function Attrs: nofree nounwind ssp uwtable
define noalias i8* @toptr(i64 %0) local_unnamed_addr #0 {
  %2 = tail call i32 (i8*, i64, i8*, ...) @snprintf(i8* nonnull dereferenceable(1) getelementptr inbounds ([40 x i8], [40 x i8]* @toptr.ptrbuf, i64 0, i64 0), i64 40, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str, i64 0, i64 0), i64 %0)
  %3 = tail call i8* @strdup(i8* getelementptr inbounds ([40 x i8], [40 x i8]* @toptr.ptrbuf, i64 0, i64 0))
  ret i8* %3
}

; Function Attrs: nofree nounwind willreturn
declare noalias i8* @strdup(i8* nocapture readonly) local_unnamed_addr #1

; Function Attrs: nofree nounwind ssp uwtable willreturn
define i64 @doit(i8* nocapture readonly %0) local_unnamed_addr #2 {
  %2 = tail call i64 @strtoll(i8* nocapture %0, i8** null, i32 10)
  ret i64 %2
}

; Function Attrs: nofree nounwind willreturn
declare i64 @strtoll(i8* readonly, i8** nocapture, i32) local_unnamed_addr #1

; Function Attrs: nofree norecurse nounwind ssp uwtable willreturn
define void @push(i64 %0) local_unnamed_addr #3 {
  %2 = load i64*, i64** @idx, align 8, !tbaa !8
  %3 = getelementptr inbounds i64, i64* %2, i64 1
  store i64* %3, i64** @idx, align 8, !tbaa !8
  store i64 %0, i64* %2, align 8, !tbaa !12
  ret void
}

; Function Attrs: nofree norecurse nounwind ssp uwtable willreturn
define i64 @pop() local_unnamed_addr #3 {
  %1 = load i64*, i64** @idx, align 8, !tbaa !8
  %2 = getelementptr inbounds i64, i64* %1, i64 -1
  store i64* %2, i64** @idx, align 8, !tbaa !8
  %3 = load i64, i64* %2, align 8, !tbaa !12
  ret i64 %3
}

; Function Attrs: nofree norecurse nounwind ssp uwtable willreturn
define i64 @add() local_unnamed_addr #3 {
  %1 = load i64*, i64** @idx, align 8, !tbaa !8
  %2 = getelementptr inbounds i64, i64* %1, i64 -1
  %3 = load i64, i64* %2, align 8, !tbaa !12
  %4 = getelementptr inbounds i64, i64* %1, i64 -2
  store i64* %4, i64** @idx, align 8, !tbaa !8
  %5 = load i64, i64* %4, align 8, !tbaa !12
  %6 = add nsw i64 %5, %3
  ret i64 %6
}

; Function Attrs: nofree nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = load i64*, i64** @idx, align 8, !tbaa !8
  %2 = bitcast i64* %1 to <2 x i64>*
  store <2 x i64> <i64 34, i64 45>, <2 x i64>* %2, align 8, !tbaa !12
  store i64* %1, i64** @idx, align 8, !tbaa !8
  %3 = tail call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(1) getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i64 79)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(i8* nocapture noundef readonly, ...) local_unnamed_addr #4

; Function Attrs: nofree nounwind
declare noundef i32 @snprintf(i8* noalias nocapture noundef writeonly, i64 noundef, i8* nocapture noundef readonly, ...) local_unnamed_addr #5

attributes #0 = { nofree nounwind ssp uwtable "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nofree nounwind willreturn "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nofree nounwind ssp uwtable willreturn "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nofree norecurse nounwind ssp uwtable willreturn "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nofree nounwind "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #5 = { nofree nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.ident = !{!7}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 12, i32 0]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 1, !"branch-target-enforcement", i32 0}
!3 = !{i32 1, !"sign-return-address", i32 0}
!4 = !{i32 1, !"sign-return-address-all", i32 0}
!5 = !{i32 1, !"sign-return-address-with-bkey", i32 0}
!6 = !{i32 7, !"PIC Level", i32 2}
!7 = !{!"Apple clang version 13.0.0 (clang-1300.0.29.3)"}
!8 = !{!9, !9, i64 0}
!9 = !{!"any pointer", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = !{!13, !13, i64 0}
!13 = !{!"long long", !10, i64 0}
