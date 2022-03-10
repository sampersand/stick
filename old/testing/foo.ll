; Prelude
target triple = "arm64-apple-macosx12.0.0"
%bool = type i8
%num = type i64
%struct.builtin.str = type { i8*, i64 } ; (ptr, len)
%struct.builtin.any = type { i8*, i64 } ; (ptr, type)
%struct.builtin.list = type { i8*, i64, i64 } ; (ptr, len, cap)

; Struct declarations
%struct.user.Person = type { %struct.builtin.str*, %num }
%struct.user.people = type { %struct.builtin.list*, %struct.builtin.any* }

; Global declarations
@globals.sam = global %struct.user.Person* null, align 8
@globals.somethin = global %struct.builtin.any* null, align 8
@globals.func = global void (%struct.builtin.str*, %num, %struct.builtin.list*)* (%struct.builtin.list*)* null, align 8

; External declarations
@globals.anum = external global %num, align 8

; String declarations
@string.-3002942069043547574.str = private unnamed_addr constant [3 x i8] c"foo", align 1
@string.-3002942069043547574 = local_unnamed_addr global %struct.builtin.str { i8* getelementptr inbounds ([3 x i8], [3 x i8]* @string.-3002942069043547574.str, i32 0, i32 0), i64 3 }, align 8


; Functions
define %struct.builtin.str* @functions.user.lol(%struct.user.Person* %0, %struct.user.people* %1, %num %2) {
  %4 = alloca %struct.builtin.str*, align 8
  store %struct.builtin.str* @string.-3002942069043547574, %struct.builtin.str** %4, align 8
  %5 = load %struct.builtin.str*, %struct.builtin.str** %4, align 8
  ret %struct.builtin.str* %5
}

define %num @functions.user.main(%struct.builtin.list* %0) {
  %2 = alloca %num, align 8
  store %num 2, %num* %2, align 8
  %3 = load %num, %num* %2, align 8
  %4 = alloca %num, align 8
  store %num 1, %num* %4, align 8
  %5 = load %num, %num* %4, align 8
  %6 = sub nsw %num %3, %5
  %7 = alloca %num, align 8
  store %num 4, %num* %7, align 8
  %8 = load %num, %num* %7, align 8
  ret %num %8
}


define %num @main() {
  %1 = call %num @functions.user.main(%struct.builtin.list* null);
  ret %num %1;
}
