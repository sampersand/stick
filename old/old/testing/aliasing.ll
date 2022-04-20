; ModuleID = 'aliasing.cpp'
source_filename = "aliasing.cpp"
target datalayout = "e-m:o-i64:64-i128:128-n32:64-S128"
target triple = "arm64-apple-macosx12.0.0"

%struct.stringy = type { i8*, i64 }
%struct.lc_list = type { i8*, i8, i64, i64 }
%struct.foo = type { i64, i32, i8, void (i32, i8*)* }

@.str = private unnamed_addr constant [4 x i8] c"foo\00", align 1
@s = global %struct.stringy { i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i64 3 }, align 8
@bar = global i32 0, align 4
@.str.1 = private unnamed_addr constant [6 x i8] c"%d %d\00", align 1
@fooey = external global i32, align 4

; Function Attrs: noinline nounwind optnone ssp uwtable
define %struct.stringy* @_Z14return_stringyv() #0 {
  %1 = alloca %struct.stringy*, align 8
  store %struct.stringy* @s, %struct.stringy** %1, align 8
  %2 = load %struct.stringy*, %struct.stringy** %1, align 8
  ret %struct.stringy* %2
}

; Function Attrs: noinline nounwind optnone ssp uwtable
define i64 @_Z4doitii(i32 %0, i32 %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, i32* %3, align 4
  store i32 %1, i32* %4, align 4
  %5 = load i32, i32* %3, align 4
  %6 = load i32, i32* %4, align 4
  %7 = srem i32 %5, %6
  %8 = sext i32 %7 to i64
  ret i64 %8
}

; Function Attrs: noinline nounwind optnone ssp uwtable
define i32 @_Z7yupperov() #0 {
  ret i32 3
}

; Function Attrs: noinline nounwind optnone ssp uwtable
define i32 @_Z3lelv() #0 {
  ret i32 1
}

; Function Attrs: noinline nounwind optnone ssp uwtable
define i32 @_Z3hehv() #0 {
  ret i32 2
}

; Function Attrs: noinline nounwind optnone ssp uwtable
define i32 @_Z3nopv() #0 {
  ret i32 3
}

; Function Attrs: noinline nounwind optnone ssp uwtable
define i64 @_Z3yupP7lc_listx(%struct.lc_list* %0, i64 %1) #0 {
  %3 = alloca %struct.lc_list*, align 8
  %4 = alloca i64, align 8
  store %struct.lc_list* %0, %struct.lc_list** %3, align 8
  store i64 %1, i64* %4, align 8
  %5 = call i32 @_Z3lelv()
  %6 = icmp ne i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %2
  %8 = call i32 @_Z3hehv()
  br label %11

9:                                                ; preds = %2
  %10 = call i32 @_Z3nopv()
  br label %11

11:                                               ; preds = %9, %7
  %12 = phi i32 [ %8, %7 ], [ %10, %9 ]
  %13 = sext i32 %12 to i64
  ret i64 %13
}

; Function Attrs: noinline optnone ssp uwtable
define i32 @_Z4lol1ii(i32 %0, i32 %1) #1 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, i32* %3, align 4
  store i32 %1, i32* %4, align 4
  br label %5

5:                                                ; preds = %9, %2
  %6 = load i32, i32* %3, align 4
  %7 = call i64 @_Z4doiti(i32 %6)
  %8 = icmp ne i64 %7, 0
  br i1 %8, label %9, label %12

9:                                                ; preds = %5
  %10 = load i32, i32* %3, align 4
  %11 = add nsw i32 %10, 1
  store i32 %11, i32* %3, align 4
  br label %5

12:                                               ; preds = %5
  %13 = load i32, i32* %4, align 4
  ret i32 %13
}

declare i64 @_Z4doiti(i32) #2

; Function Attrs: noinline norecurse optnone ssp uwtable
define i32 @main() #3 {
  %1 = alloca %struct.foo, align 8
  %2 = alloca i32, align 4
  call void @_Z5doit2IbE3fooIT_Em(%struct.foo* sret(%struct.foo) align 8 %1, i64 3)
  store i32 39192, i32* %2, align 4
  %3 = getelementptr inbounds %struct.foo, %struct.foo* %1, i32 0, i32 0
  %4 = load i64, i64* %3, align 8
  %5 = getelementptr inbounds %struct.foo, %struct.foo* %1, i32 0, i32 1
  %6 = load i32, i32* %5, align 8
  %7 = load i32, i32* @fooey, align 4
  %8 = add nsw i32 %6, %7
  %9 = load i32, i32* %2, align 4
  %10 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str.1, i64 0, i64 0), i64 %4, i32 %8, i32 %9)
  ret i32 0
}

; Function Attrs: noinline optnone ssp uwtable
define linkonce_odr void @_Z5doit2IbE3fooIT_Em(%struct.foo* noalias sret(%struct.foo) align 8 %0, i64 %1) #1 {
  %3 = alloca i64, align 8
  %4 = alloca i8, align 1
  store i64 %1, i64* %3, align 8
  store i8 1, i8* %4, align 1
  %5 = getelementptr inbounds %struct.foo, %struct.foo* %0, i32 0, i32 0
  %6 = load i64, i64* %3, align 8
  %7 = trunc i64 %6 to i32
  %8 = call i64 @_Z4doiti(i32 %7)
  store i64 %8, i64* %5, align 8
  %9 = getelementptr inbounds %struct.foo, %struct.foo* %0, i32 0, i32 1
  store i32 3, i32* %9, align 8
  %10 = getelementptr inbounds %struct.foo, %struct.foo* %0, i32 0, i32 2
  %11 = load i8, i8* %4, align 1
  %12 = trunc i8 %11 to i1
  %13 = zext i1 %12 to i8
  store i8 %13, i8* %10, align 4
  %14 = getelementptr inbounds %struct.foo, %struct.foo* %0, i32 0, i32 3
  store void (i32, i8*)* null, void (i32, i8*)** %14, align 8
  ret void
}

declare i32 @printf(i8*, ...) #2

attributes #0 = { noinline nounwind optnone ssp uwtable "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { noinline optnone ssp uwtable "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { noinline norecurse optnone ssp uwtable "disable-tail-calls"="false" "frame-pointer"="non-leaf" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="apple-m1" "target-features"="+aes,+crc,+crypto,+dotprod,+fp-armv8,+fp16fml,+fullfp16,+lse,+neon,+ras,+rcpc,+rdm,+sha2,+sha3,+sm4,+v8.5a,+zcm,+zcz" "unsafe-fp-math"="false" "use-soft-float"="false" }

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
