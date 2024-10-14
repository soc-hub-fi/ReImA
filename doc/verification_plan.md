# CSI Verification

Degrees of Freedom:
- 4, 2 or 1 lanes
- 4, 2 or 1 Pixel Per Clock configuration
- RAW8, RAW10, RGB888, RGB656, YUV422 datatypes
- Virtual channel and data type interleaving
- Bayer filter types in case of RAW datatype tests (RGGB, BGGR, GBRG, GRBG)
- Lane aligner depth verification
- ECC and CRC error checks
- Interrupts (not sure how many)

## Legend for Status and On Pipeline colums 
| Status        | Icon                 |
| ------------- | -------------------- |
|Passing        | :heavy_check_mark:   |
|Failing        | :x:                  |
|Not Implemented| :white_large_square: |


| On Pipelines                                                        | Icon                    |
| --------------------------------------------------------------------| ------------------------|
|Test runs always<br><sub>Push, Merge Request, Night, and Weekly</sub>| :white_check_mark:      |
|Test runs on Merge Requests, Nightly, and Weekly                     | :arrow_heading_up:      |
|Test runs on Nightly and Weekly only                                 | :night_with_stars:      |
|Test runs on Weekly only                                             | :calendar:              |
|Test is not on CI Pipeline                                           | :heavy_multiplication_x:|

## Single-core general tests

|Test Name|Description|Status|On Pipeline|
|---------|-----------|------|-----------|
|extmem64bit|Simple read & write 64-bit data|:heavy_check_mark:|:white_check_mark:|
|atomic_fetchxor64bit|64-bit atomic fetch-and-XOR test|:heavy_check_mark:|:white_check_mark:|
|extmem32bit|Simple read & write 32-bit data|:heavy_check_mark:|:arrow_heading_up:|
|extmem16bit|Simple read & write 16-bit data|:heavy_check_mark:|:arrow_heading_up:|
|extmem8bit|Simple read & write 8-bit data|:heavy_check_mark:|:arrow_heading_up:|
|atomic_swap64bit|64-bit atomic swap test|:heavy_check_mark:|:arrow_heading_up:|
|atomic_fetchadd64bit|64-bit atomic fetch-and-add test|:heavy_check_mark:|:night_with_stars:|
|atomic_fetchand64bit|64-bit atomic fetch-and-AND test|:heavy_check_mark:|:night_with_stars:|
|atomic_fetchor64bit|64-bit atomic fetch-and-OR test|:heavy_check_mark:|:night_with_stars:|
|atomic_fetchadd32bit|32-bit atomic fetch-and-add test|:heavy_check_mark:|:night_with_stars:|
|atomic_fetchand32bit|32-bit atomic fetch-and-AND test|:heavy_check_mark:|:night_with_stars:|
|atomic_fetchor32bit|32-bit atomic fetch-and-OR test|:heavy_check_mark:|:night_with_stars:|
|atomic_fetchxor32bit|32-bit atomic fetch-and-XOR test|:heavy_check_mark:|:night_with_stars:|
|atomic_swap32bit|32-bit atomic swap test|:heavy_check_mark:|:night_with_stars:|
|doubles|Floating point test with 64-bit doubles|:heavy_check_mark:|:night_with_stars:|
|doubles_conv|Floating point test with 64-bit doubles, includes type conversions|:heavy_check_mark:|:night_with_stars:|
|floats_conv|Floating point test with 32-bit floats, includes type conversions|:heavy_check_mark:|:night_with_stars:|
|floats|Floating point test with 32-bit floats|:heavy_check_mark:|:night_with_stars:|
|lfsr8bit|Linear-feedback shift register test with 8-bit register|:heavy_check_mark:|:calendar:|
|lfsr16bit|Linear-feedback shift register test with 16-bit register|:heavy_check_mark:|:calendar:|
|lfsr16bit_fence|Linear-feedback shift register test with 16-bit register, also includes fence operations|:heavy_check_mark:|:calendar:|
|lfsr16bit_fence_i|Linear-feedback shift register test with 16-bit register, also includes fence operations|:heavy_check_mark:|:calendar:|
|lfsr64bit_x300|Linear-feedback shift register test with 64-bit register, 300 iterations|:heavy_check_mark:|:calendar:|
|lfsr64bit_x2000|Linear-feedback shift register test with 64-bit register, 2000 iterations|:heavy_check_mark:|:heavy_multiplication_x:|
|cache_evict8bit_rand_mm|8-bit cache evict test|:heavy_check_mark:|:calendar:|
|cache_evict32bit_rand_mm|32-bit cache evict test|:heavy_check_mark:|:calendar:| 
|cache_evict64bit_rand_mm|64-bit cache evict test|:heavy_check_mark:|:calendar:|
|cache_evict16bit_rand_mm|16-bit cache evict test|:heavy_check_mark:|:calendar:|


