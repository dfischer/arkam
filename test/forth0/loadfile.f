require: lib/core.f

loadfile: test/assets/1byte.bin as: 1byte.bin
here as: after_1byte.bin

"1byte" [
  1byte.bin filesize 1 = "1byte size" ASSERT
  1byte.bin filedata b@ 64 = "1byte data" ASSERT
  after_1byte.bin cell mod 0 = "1byte aligned" ASSERT
  1byte.bin filedata "@" s= "1byte null terminated" ASSERT
  ok
] CHECK



loadfile: test/assets/10byte.txt as: 10byte.txt
here as: after_10byte.txt

"10byte" [
  10byte.txt filesize 10 = "10byte size" ASSERT
  after_10byte.txt cell mod 0 = "10byte aligned" ASSERT
  10byte.txt filedata "123456789\n" s= "10byte null terminated" ASSERT
  ok
] CHECK
