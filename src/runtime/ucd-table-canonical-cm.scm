#| -*-Scheme-*-

Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
    1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016,
    2017 Massachusetts Institute of Technology

This file is part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; UCD property: canonical-cm (canonical-composition-mapping)

;;; Generated from Unicode 9.0.0

(declare (usual-integrations))

(define (ucd-canonical-cm-value char)
  (let ((sv (char->integer char)))
    (vector-ref ucd-canonical-cm-table-5 (bytevector-u16be-ref ucd-canonical-cm-table-4 (fix:lsh (fix:or (fix:lsh (bytevector-u16be-ref ucd-canonical-cm-table-3 (fix:lsh (fix:or (fix:lsh (bytevector-u8-ref ucd-canonical-cm-table-2 (fix:or (fix:lsh (bytevector-u8-ref ucd-canonical-cm-table-1 (fix:or (fix:lsh (bytevector-u8-ref ucd-canonical-cm-table-0 (fix:lsh sv -16)) 4) (fix:and 15 (fix:lsh sv -12)))) 4) (fix:and 15 (fix:lsh sv -8)))) 4) (fix:and 15 (fix:lsh sv -4))) 1)) 4) (fix:and 15 sv)) 1)))))

(define-deferred ucd-canonical-cm-table-0
  (vector->bytevector '#(0 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2)))

(define-deferred ucd-canonical-cm-table-1
  (vector->bytevector '#(0 1 2 3 4 4 4 4 4 4 5 6 7 8 4 4 4 9 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4)))

(define-deferred ucd-canonical-cm-table-2
  (vector->bytevector '#(0 1 2 3 4 5 6 5 5 7 5 8 9 10 5 5 11 12 5 5 5 5 5 5 5 5 5 13 5 5 14 15 5 16 17 5 5 5 5 5 5 5 5 5 5 5 5 5 18 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 5 5 5 5 5 5 5 5 63 64 5 65 66 67 5 5 5 5 5 5 5 5 5 5)))

(define-deferred ucd-canonical-cm-table-3
  (vector->bytevector-u16be
   '#(0  0   0  1   2   3 4   5 0   0 6   0   7 8   9 10  11 12  0   0 13  14 15  16 0   0   17 18  0 0   19 0   0   0 20  0 0   0 0   0   0 21  0 0   0 0   0   0 0   0 0   0 0   0   0 0   0 22  23 24  25  26 0   0 27  28 29  30  31 32  0 33  0 0   0   0 0   34 35  0 0   0   0 0   0 0   0 0   0   0 0   0 0   0 0   0   0 0   36 0   37 0   0   0 0   0 0   0 38  39  0 0   0 0   40  41  0   0 0   0 0   0 0   0   42  0   0 0   0 0   0   0 43  0 0   0 0   44  0 0   45 0   0 0   0   0 0   0 46  0 0   0   0 0   0 47  48 0   0   0 0   0 0   0 49  0   0 0   0 0   0 0   0   50 0   0 0   0 51  0   0   0   0 0   0 0   0   0 0   0 0   0 52  53  0 0   0 0   0 0   0   0 0   0 0   0 0   0   54 55  0 56  57 0   0   0 0   0 0   0 0   0   0 0   0 0   0 58  0   59 60  0 0   0 61  62  63 0   0 0   64 65  66  67 68  69 70  71 0   0   0 72  73 0   0 74  0   0 0   0 0   0 0   0   0 75  0 0   0 76  0   0 77  0 78  79 80  0   81 82  83 84  85 86  0   0 0   0 0   0 0   0   87 88  89 90  0 91  92  93 94
      95 96  97 98  99  0 100 0 101 0 102 103 0 104 0 105 0  106 107 0 108 0  109 0  110 111 0  112 0 113 0  114 115 0 116 0 117 0 118 119 0 120 0 121 0 122 123 0 124 0 125 0 126 127 0 128 0 129 0  130 131 0  132 0 133 0  134 135 0  136 0 137 0 138 139 0 140 0  141 0 142 143 0 144 0 145 0 146 147 0 148 0 149 0 150 151 0 152 0  153 0  154 155 0 156 0 157 0 158 159 0 160 0 161 0   162 163 0 164 0 165 0 166 167 0   168 0 169 0 170 171 0 172 0 173 0 174 175 0 176 0  177 0 178 179 0 180 0 181 0 182 183 0 184 0 185 0  186 187 0 188 0 189 0 190 191 0 192 0 193 0 194 195 0  196 0 197 0 198 199 0   200 0 201 0 202 203 0 204 0 205 0 206 207 0 208 0 209 0 210 211 0 212 0 213 0 214 215 0  216 0 217 0  218 219 0 220 0 221 0 222 223 0 224 0 225 0 226 227 0  228 0 229 0 230 231 0  232 0 233 0  234 235 0  236 0  237 0  238 239 0 240 0  241 0 242 243 0 244 0 245 0 246 247 0 248 0 249 0 250 251 0 252 0 253 0  254 255 0  256 0  257 0  258 259 0 260 0 261 0 262 263 0  264 0  265 0 266 267 0  268
      0  269 0  270 271 0 272 0 273 0 274 275 0 276 0 277 0  278 279 0 280 0  281 0  282 283 0  284 0 285 0  286 287 0 288 0 289 0 290 291 0 292 0 293 0 294 295 0 296 0 297 0 298 299 0 300 0 301 0  302 303 0  304 0 305 0  306 307 0  308 0 309 0 310 311 0 312 0  313 0 314 315 0 316 0 317 0 318 319 0 320 0 321 0 322 323 0 324 0  325 0  326 327 0 328 0 329 0 330 331 0 332 0 333 0   334 335 0 336 0 337 0 338 339 0   340 0 341 0 342 343 0 344 0 345 0 346 347 0 348 0  349 0 350 351 0 352 0 353 0 354 355 0 356 0 357 0  358 359 0 360 0 361 0 362 363 0 364 0 365 0 366 367 0  368 0 369 0 370 371 0   372 0 373 0 374 375 0 376 0 377 0 378 379 0 380 0 381 0 382 383 0 384 0 385 0 386 387 0  388 0 389 0  390 391 0 392 0 393 0 394 395 0 396 0 397 0 398 399 0  400 0 401 0 402 403 0  404 0 405 0  406 407 0  408 0  409 0  410 411 0 412 0  413 0 414 415 0 416 0 417 0 418 419 0 420 0 421 0 422 423 0 424 0 425 0  426 427 0  428 0  429 0  430 431 0 432 0 433 0 434 435 0  436 0  437 0 438 439 0  440
      0  441 0  442 443 0 444 0 445 0 446 447 0 448 0 449 0  450 451 0 452 0  453 0  454 455 0  456 0 457 0  458 459 0 460 0 461 0 462 463 0 464 0 465 0 466 467 0 468 0 469 0 470 471 0 472 0 473 0  474 475 0  476 0 477 0  478 479 0  480 0 481 0 482 483 0 484 0  485 0 486 487 0 488 0 489 0 490 491 0 492 0 493 0 494 495 0 496 0  0   0  0   0   0 0   0 0   0 0   0   0 0   0 0   497 498 0   0 0   0 0   0 0   0   499 0   0 0   0 0   0   0 0   0 0   0 0   0   0 0   0  500 0 0   0   0 0   0 0   0 0   0   0 0   0 0   0  0   0   0 0   0 0   0 501 0   0 0   0 0   0 0   0   0  0   0 0   0 0   0   502 0   0 0   0)))

(define-deferred ucd-canonical-cm-table-4
  (vector->bytevector-u16be
   '#(0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0 0   0 0 0  0   0   0   0 1   2   3 0  0   4   5 6 7   8 9 10 11  12  13  14  15  16  17  18  19  0   20  21  22  23  24  25  26  27  28  0   0   0   0   0   0   29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  0   45 46  47  48  49 50  51  52  53 0   0   0   0 0   0   0   0   0   0   0   0   0   54  0   0 0 0   0   0   0   0   0   55  0 56  57 58  59  0   0   60  0 0   0   0 61  0   0   0 0   62  63 64  0   65  0   0 0 66  0   0   0   0   0   67  0   68  69  70  71  0   0 72  0 0   0 0   73 0   0 0   0   74  75  76 0   77  0   0   0   78  0   0   0   0   0   79  80  0   0   0 0   0   0   0 0   0   0   0   0   0   0 81  82  0   0   0   0   0   0 0   0   0   0   0 0   0   0   0 0   0   0   0   0 0   0 0 0   83  84  0   0   0   0 0   0   0   0   0   0   0   0   85  86  0   0   0   0   87  88  0   0   0   0   0   0   89  90  91  92 0   0 0   0 0   0   0   0   0   0 0   0
      0   0   0   0   0   0   0   93  94  95  0   0   0   0   0   0   0   0   0 0 0   0 0 96 97  0   0   0 0   0   0 98 0   0   0 0 0   0 0 0  0   0   0   0   0   0   0   0   0   0   99  100 0   0   0   0   0   0   0   0   0   0   101 102 103 104 0   0   0   0   105 106 0   0   107 0   0   0   0   0   0   0   0  0   0   0   0  0   0   108 0  0   0   109 0 110 0   111 0   0   0   0   0   112 0   113 0 0 0   114 0   0   0   115 0   0 116 0  117 0   0   118 0   0 0   119 0 120 0   121 0 0   0   0  0   122 0   123 0 0 0   124 0   0   0   125 126 127 0   0   128 0   0   0 129 0 0   0 0   0  0   0 0   0   0   0   0  0   0   0   0   0   0   0   130 0   0   0   0   0   0   0   0 0   131 0   0 132 0   133 134 135 136 0 137 0   0   0   138 0   0   0 0   139 0   0   0 140 0   0   0 141 0   142 0   0 143 0 0 144 0   145 146 147 148 0 149 0   0   0   150 0   0   0   0   151 0   0   0   152 0   0   0   153 0   154 0   0   0   0   0   0  0   0 155 0 0   0   0   0   0   0 0   0
      0   0   0   0   156 157 0   0   0   0   0   0   0   0   0   0   0   0   0 0 0   0 0 0  158 159 0   0 0   0   0 0  0   0   0 0 0   0 0 0  160 161 0   0   0   0   0   0   0   0   0   0   0   0   0   162 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   163 0   164 0   0   0   0   0   0   165 0  0   0   0   0  0   0   0   0  0   0   0   0 0   0   0   166 0   0   167 0   0   0   0   0 0 0   0   0   0   0   0   0   0 0   0  0   0   168 0   0   0 0   0   0 0   169 0   0 170 0   0  0   0   0   0   0 0 0   0   0   0   0   0   0   0   0   0   0   171 0   0 0   0 0   0 0   0  0   0 0   0   0   0   0  172 0   0   0   0   0   0   0   0   0   0   173 0   0   0   0 0   0   0   0 0   0   0   0   0   0   0 0   0   0   0   174 175 0   0 0   0   0   0   0 0   0   0   0 0   0   0   176 0 0   0 0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0   0   177 0   0   0   0   0   0   178 0   0   0   179 0  0   0 0   0 0   0   0   0   0   0 180 181
      0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   182 0 0 183 0 0 0  0   0   0   0 0   184 0 0  0   0   0 0 0   0 0 0  185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   204 0   205 0   206 0  207 0   208 0  0   0   209 0  0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0 0 0   0   0   0   0   0   210 0 211 0  212 213 0   0   214 0 0   0   0 0   0   0   0 0   0   0  0   0   0   0   0 0 0   0   215 216 0   0   0   0   0   0   0   0   0   0 0   0 0   0 0   0  0   0 217 218 0   0   0  0   0   0   219 220 0   0   0   0   0   0   0   0   0   0   0 0   221 222 0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0 0   0   0   0   0 0   223 224 0 0   0   0   0   0 0   0 0 0   0   0   0   0   0   0 0   0   225 226 0   0   227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 0   0  0   0 0   0 245 246 0   0   0   0 0   0
      247 248 249 250 251 252 253 254 255 256 257 258 259 260 261 262 263 264 0 0 0   0 0 0  265 266 0   0 0   0   0 0  267 268 0 0 0   0 0 0  269 270 0   0   0   0   0   0   271 272 0   0   0   0   0   0   0   273 0   0   0   0   0   0   274 275 276 277 278 279 280 281 282 283 284 285 286 287 288 289 290 0   0  0   291 0   0  0   0   0   0  0   292 0   0 0   0   0   0   0   0   0   293 0   0   0   0 0 0   0   0   294 0   0   0   0 0   0  295 0   0   0   0   0 0   0   0 0   0   0   0 0   0   0  296 0   0   0   0 0 0   0   297 0   298 0   299 0   300 0   0   0   0   0 0   0 0   0 0   0  301 0 302 0   303 0   0  0   0   0   0   0   0   0   0   0   0   0   0   304 0   0   0 0   305 0   0 306 0   0   0   0   0   0 0   307 0   308 0   0   0   0 0   0   0   0   0 0   0   0   0 0   0   0   0   0 0   0 0 0   309 0   0   0   0   0 0   310 0   311 0   0   312 0   0   0   0   313 0   0   0   314 0   0   315 316 0   0   0   0   0   0  0   0 0   0 0   0   317 318 0   0 319 320
      0   0   321 322 323 324 0   0   0   0   325 326 0   0   327 328 0   0   0 0 0   0 0 0  0   329 330 0 0   0   0 0  0   0   0 0 0   0 0 0  0   0   331 0   0   0   0   0   332 333 0   334 0   0   0   0   0   0   335 336 337 338 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   339 0   0   0   0  340 0   341 0  342 0   343 0  344 0   345 0 346 0   347 0   348 0   349 0   350 0   351 0 0 352 0   353 0   354 0   0   0 0   0  0   355 0   0   356 0 0   357 0 0   358 0   0 359 0   0  0   0   0   0   0 0 0   0   0   0   0   0   0   0   0   360 0   0   0   0 0   0 0   0 361 0  0   0 0   362 0   363 0  364 0   365 0   366 0   367 0   368 0   369 0   370 0   371 0 372 0   373 0 0   374 0   375 0   376 0 0   0   0   0   0   377 0   0 378 0   0   379 0 0   380 0   0 381 0   0   0   0 0   0 0 0   0   0   0   0   0   0 0   0   0   0   0   382 383 384 385 0   0   0   0   0   0   0   0   0   0   386 0   0   387 0   0   0  0   0 0   0 0   0   0   0   0   0 0   0
      0   0   0   0   0   0   0   0   0   0   0   0   388 0   0   0   0   0   0 0 0   0 0 0  389 0   0   0 0   0   0 0  0   0   0 0 390 0 0 0  0   0   0   0   0   0   0   0   391 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   392 0   0   0   0   0   0  0   0   0   0  0   393 0   0  0   0   0   0 0   0   0   0   0   394 0   0   0   0   0   0 0 0   0   0   0   395 0   0   0 0   0  0   0   0   0   0   0 0   0   0 0   0   0   0 0   0   0  0   0   0   0   0 0 396 0   0   0   0   0   0   0   0   0   0   0   397 0 0   0 0   0 0   0  0   0 0   0   398 0   0  0   0   0   0   0   0   0   0   0   399 0   0   0   0   0   0 0   0   0   0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0 0   0   400 0   0 0   0   0   0 0   0   0   0   0 401 0 0 0   0   0   0   0   0   0 0   0   402 0   0   0   0   0   0   0   0   0   0   0   403 0   0   0   0   0   0   0   0   0   0   0  0   0 0   0 0   0   0   0   0   0 0   0
      0   0   0   0   404 0   0   0   0   0   0   0   0   0   0   0   405 0   0 0 0   0 0 0  0   0   0   0 406 0   0 0  0   0   0 0 0   0 0 0  407 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   408 0   0   0   0   0   0   0   0   0   0   0   409 0   0  0   0   0   0  0   0   0   0  0   410 0   0 0   0   0   0   0   0   0   0   0   411 0   0 0 0   0   0   0   0   0   0   0 0   0  0   0   0   0   0   0 0   0   0 0   0   0   0 0   412 0  0   0   0   0   0 0 0   0   0   0   413 0   0   0   0   0   0   0   0   0 0   0 414 0 0   0  0   0 0   0   0   0   0  0   415 0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0   0   0 0   0   0   0   0   0   0 0   0   416 0   0   0   0   0 0   0   0   0   0 0   417 0   0 0   0   0   0   0 0   0 0 0   418 0   0   0   0   0 0   0   0   0   0   0   419 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0 0   0 0   0   0   0   420 0 0   0
      0   0   0   0   0   0   0   0   421 0   0   0   0   0   0   0   0   0   0 0 422 0 0 0  0   0   0   0 0   0   0 0  423 0   0 0 0   0 0 0  0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   424 0   0   0   0   0   0   0   0   0   0   0   425 0   0   0   0   0   0   0   0   0   0  0   426 0   0  0   0   0   0  0   0   0   0 0   427 0   0   0   0   0   0   0   0   0   0 0 0   0   0   0   0   0   0   0 0   0  0   0   0   0   0   0 428 0   0 0   0   0   0 0   0   0  0   0   429 0   0 0 0   0   0   0   0   0   0   0   430 0   0   0   0   0 0   0 0   0 0   0  431 0 0   0   0   0   0  0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0   0   0 0   432 0   0   0   0   0 0   0   0   0   0   0   433 0 0   0   0   0   0 0   0   0   0 0   434 0   0   0 0   0 0 0   0   0   0   0   435 0 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  436 0 0   0 0   0   0   0   0   0 0   0
      437 0   0   0   0   0   0   0   0   0   0   0   438 0   0   0   0   0   0 0 0   0 0 0  439 0   0   0 0   0   0 0  0   0   0 0 0   0 0 0  0   0   0   0   0   0   0   0   0   0   0   0   440 0   0   0   0   0   0   0   0   0   0   0   441 0   0   0   0   0   0   0   0   0   0   0   442 0   0   0   0   0   0  0   0   0   0  0   443 0   0  0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0 0 0   0   0   0   0   0   0   0 444 0  0   0   0   0   0   0 0   0   0 0   445 0   0 0   0   0  0   0   0   0   0 0 446 0   0   0   0   0   0   0   0   0   0   0   447 0 0   0 0   0 0   0  0   0 0   0   0   0   0  0   0   0   0   0   0   0   0   0   0   0   0   0   448 0   0 0   0   0   0 0   0   0   0   0   449 0 0   0   0   0   0   0   0   0 0   0   450 0   0 0   0   0   0 0   0   0   0   0 451 0 0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   452 0   0   0   0   0   0   0  0   0 0   0 453 0   0   0   0   0 0   0
      0   0   0   0   454 0   0   0   0   0   0   0   0   0   0   0   455 0   0 0 0   0 0 0  0   0   0   0 0   0   0 0  0   0   0 0 0   0 0 0  0   0   0   0   456 0   0   0   0   0   0   0   0   0   0   0   457 0   0   0   0   0   0   0   0   0   0   0   458 0   0   0   0   0   0   0   0   0   0   0   459 0   0  0   0   0   0  0   0   0   0  0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0 0 460 0   0   0   0   0   0   0 0   0  0   0   461 0   0   0 0   0   0 0   0   0   0 0   462 0  0   0   0   0   0 0 0   0   0   0   463 0   0   0   0   0   0   0   0   0 0   0 0   0 0   0  0   0 0   0   0   0   0  0   0   0   0   0   464 0   0   0   0   0   0   0   0   0   0 0   465 0   0 0   0   0   0   0   0   0 0   0   466 0   0   0   0   0 0   0   0   0   0 0   467 0   0 0   0   0   0   0 0   0 0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0   0   0   468 0   0   0   0   0   0   0   0   0   0   0   469 0   0   0  0   0 0   0 0   0   0   0   470 0 0   0
      0   0   0   0   0   0   0   0   471 0   0   0   0   0   0   0   0   0   0 0 0   0 0 0  0   0   0   0 0   0   0 0  0   0   0 0 472 0 0 0  0   0   0   0   0   0   0   0   473 0   0   0   0   0   0   0   0   0   0   0   474 0   0   0   0   0   0   0   0   0   0   0   475 0   0   0   0   0   0   0   0   0   0  0   0   0   0  0   0   0   0  0   0   0   0 0   0   0   0   0   476 0   0   0   0   0   0 0 0   0   0   0   477 0   0   0 0   0  0   0   0   0   0   0 478 0   0 0   0   0   0 0   0   0  0   0   479 0   0 0 0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0 0   0 0   0  0   0 0   0   480 0   0  0   0   0   0   0   0   0   0   0   481 0   0   0   0   0   0 0   0   0   0 0   482 0   0   0   0   0 0   0   0   0   0   0   483 0 0   0   0   0   0 0   0   0   0 0   0   0   0   0 0   0 0 0   0   0   0   0   0   0 0   0   484 0   0   0   0   0   0   0   0   0   0   0   485 0   0   0   0   0   0   0   0   0   0   0  486 0 0   0 0   0   0   0   0   0 0   0
      487 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0 0   0 0 0  0   0   0   0 488 0   0 0  0   0   0 0 0   0 0 0  489 0   0   0   0   0   0   0   0   0   0   0   490 0   0   0   0   0   0   0   0   0   0   0   491 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0   0   0  0   0   0   0  0   492 0   0 0   0   0   0   0   0   0   0   0   493 0   0 0 0   0   0   0   0   0   0   0 494 0  0   0   0   0   0   0 0   0   0 0   495 0   0 0   0   0  0   0   0   0   0 0 0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0 496 0 0   0  0   0 0   0   0   0   0  0   497 0   0   0   0   0   0   0   0   0   0   0   498 0   0 0   0   0   0 0   0   0   0   0   499 0 0   0   0   0   0   0   0   0 0   0   0   0   0 0   0   0   0 0   0   0   0   0 0   0 0 0   500 0   0   0   0   0 0   0   0   0   0   0   501 0   0   0   0   0   0   0   0   0   0   0   502 0   0   0   0   0   0   0  0   0 0   0 503 0   0   0   0   0 0   0
      0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0 504 0 0 0  0   0   0   0 0   0   0 0  505 0   0 0 0   0 0 0  0   0   0   0   506 0   0   0   0   0   0   0   0   0   0   0   507 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   508 0   0  0   0   0   0  0   0   0   0 0   509 0   0   0   0   0   0   0   0   0   0 0 510 0   0   0   0   0   0   0 0   0  0   0   511 0   0   0 0   0   0 0   0   0   0 0   0   0  0   0   0   0   0 0 0   0   0   0   0   0   0   0   512 0   0   0   0   0 0   0 0   0 0   0  513 0 0   0   0   0   0  0   0   0   0   0   514 0   0   0   0   0   0   0   0   0   0 0   515 0   0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0 0   0   0   0   0 0   0   0   0 0   516 0   0   0 0   0 0 0   0   0   0   0   517 0 0   0   0   0   0   0   0   0   0   0   518 0   0   0   0   0   0   0   0   0   0   0   519 0   0   0  0   0 0   0 0   0   0   0   0   0 0   0
      0   0   0   0   0   0   0   0   0   0   0   0   520 0   0   0   0   0   0 0 0   0 0 0  521 0   0   0 0   0   0 0  0   0   0 0 522 0 0 0  0   0   0   0   0   0   0   0   523 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   524 0   0   0   0   0   0  0   0   0   0  0   525 0   0  0   0   0   0 0   0   0   0   0   526 0   0   0   0   0   0 0 0   0   0   0   527 0   0   0 0   0  0   0   0   0   0   0 0   0   0 0   0   0   0 0   0   0  0   0   0   0   0 0 528 0   0   0   0   0   0   0   0   0   0   0   529 0 0   0 0   0 0   0  0   0 0   0   530 0   0  0   0   0   0   0   0   0   0   0   531 0   0   0   0   0   0 0   0   0   0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0 0   0   532 0   0 0   0   0   0 0   0   0   0   0 533 0 0 0   0   0   0   0   0   0 0   0   534 0   0   0   0   0   0   0   0   0   0   0   535 0   0   0   0   0   0   0   0   0   0   0  0   0 0   0 0   0   0   0   0   0 0   0
      0   0   0   0   536 0   0   0   0   0   0   0   0   0   0   0   537 0   0 0 0   0 0 0  0   0   0   0 538 0   0 0  0   0   0 0 0   0 0 0  539 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   540 0   0   0   0   0   0   0   0   0   0   0   541 0   0  0   0   0   0  0   0   0   0  0   542 0   0 0   0   0   0   0   0   0   0   0   543 0   0 0 0   0   0   0   0   0   0   0 0   0  0   0   0   0   0   0 0   0   0 0   0   0   0 0   544 0  0   0   0   0   0 0 0   0   0   0   545 0   0   0   0   0   0   0   0   0 0   0 546 0 0   0  0   0 0   0   0   0   0  0   547 0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0   0   0 0   0   0   0   0   0   0 0   0   548 0   0   0   0   0 0   0   0   0   0 0   549 0   0 0   0   0   0   0 0   0 0 0   550 0   0   0   0   0 0   0   0   0   0   0   551 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0 0   0 0   0   0   0   552 0 0   0
      0   0   0   0   0   0   0   0   553 0   0   0   0   0   0   0   0   0   0 0 554 0 0 0  0   0   0   0 0   0   0 0  555 0   0 0 0   0 0 0  0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   556 0   0   0   0   0   0   0   0   0   0   0   557 0   0   0   0   0   0   0   0   0   0  0   558 0   0  0   0   0   0  0   0   0   0 0   559 0   0   0   0   0   0   0   0   0   0 0 0   0   0   0   0   0   0   0 0   0  0   0   0   0   0   0 560 0   0 0   0   0   0 0   0   0  0   0   561 0   0 0 0   0   0   0   0   0   0   0   562 0   0   0   0   0 0   0 0   0 0   0  563 0 0   0   0   0   0  0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0   0   0 0   564 0   0   0   0   0 0   0   0   0   0   0   565 0 0   0   0   0   0 0   0   0   0 0   566 0   0   0 0   0 0 0   0   0   0   0   567 0 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  568 0 0   0 0   0   0   0   0   0 0   0
      569 0   0   0   0   0   0   0   0   0   0   0   570 0   0   0   0   0   0 0 0   0 0 0  571 0   0   0 0   0   0 0  0   0   0 0 0   0 0 0  0   0   0   0   0   0   0   0   0   0   0   0   572 0   0   0   0   0   0   0   0   0   0   0   573 0   0   0   0   0   0   0   0   0   0   0   574 0   0   0   0   0   0  0   0   0   0  0   575 0   0  0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0 0 0   0   0   0   0   0   0   0 576 0  0   0   0   0   0   0 0   0   0 0   577 0   0 0   0   0  0   0   0   0   0 0 578 0   0   0   0   0   0   0   0   0   0   0   579 0 0   0 0   0 0   0  0   0 0   0   0   0   0  0   0   0   0   0   0   0   0   0   0   0   0   0   580 0   0 0   0   0   0 0   0   0   0   0   581 0 0   0   0   0   0   0   0   0 0   0   582 0   0 0   0   0   0 0   0   0   0   0 583 0 0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   584 0   0   0   0   0   0   0  0   0 0   0 585 0   0   0   0   0 0   0
      0   0   0   0   586 0   0   0   0   0   0   0   0   0   0   0   587 0   0 0 0   0 0 0  0   0   0   0 0   0   0 0  0   0   0 0 0   0 0 0  0   0   0   0   588 0   0   0   0   0   0   0   0   0   0   0   589 0   0   0   0   0   0   0   0   0   0   0   590 0   0   0   0   0   0   0   0   0   0   0   591 0   0  0   0   0   0  0   0   0   0  0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0 0 592 0   0   0   0   0   0   0 0   0  0   0   593 0   0   0 0   0   0 0   0   0   0 0   594 0  0   0   0   0   0 0 0   0   0   0   595 0   0   0   0   0   0   0   0   0 0   0 0   0 0   0  0   0 0   0   0   0   0  0   0   0   0   0   596 0   0   0   0   0   0   0   0   0   0 0   597 0   0 0   0   0   0   0   0   0 0   0   598 0   0   0   0   0 0   0   0   0   0 0   599 0   0 0   0   0   0   0 0   0 0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0   0   0   600 0   0   0   0   0   0   0   0   0   0   0   601 0   0   0  0   0 0   0 0   0   0   0   602 0 0   0
      0   0   0   0   0   0   0   0   603 0   0   0   0   0   0   0   0   0   0 0 0   0 0 0  0   0   0   0 0   0   0 0  0   0   0 0 604 0 0 0  0   0   0   0   0   0   0   0   605 0   0   0   0   0   0   0   0   0   0   0   606 0   0   0   0   0   0   0   0   0   0   0   607 0   0   0   0   0   0   0   0   0   0  0   0   0   0  0   0   0   0  0   0   0   0 0   0   0   0   0   608 0   0   0   0   0   0 0 0   0   0   0   609 0   0   0 0   0  0   0   0   0   0   0 610 0   0 0   0   0   0 0   0   0  0   0   611 0   0 0 0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0 0   0 0   0  0   0 0   0   612 0   0  0   0   0   0   0   0   0   0   0   613 0   0   0   0   0   0 0   0   0   0 0   614 0   0   0   0   0 0   0   0   0   0   0   615 0 0   0   0   0   0 0   0   0   0 0   0   0   0   0 0   0 0 0   0   0   0   0   0   0 0   0   616 0   0   0   0   0   0   0   0   0   0   0   617 0   0   0   0   0   0   0   0   0   0   0  618 0 0   0 0   0   0   0   0   0 0   0
      619 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0 0   0 0 0  0   0   0   0 620 0   0 0  0   0   0 0 0   0 0 0  621 0   0   0   0   0   0   0   0   0   0   0   622 0   0   0   0   0   0   0   0   0   0   0   623 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0   0   0  0   0   0   0  0   624 0   0 0   0   0   0   0   0   0   0   0   625 0   0 0 0   0   0   0   0   0   0   0 626 0  0   0   0   0   0   0 0   0   0 0   627 0   0 0   0   0  0   0   0   0   0 0 0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0 628 0 0   0  0   0 0   0   0   0   0  0   629 0   0   0   0   0   0   0   0   0   0   0   630 0   0 0   0   0   0 0   0   0   0   0   631 0 0   0   0   0   0   0   0   0 0   0   0   0   0 0   0   0   0 0   0   0   0   0 0   0 0 0   632 0   0   0   0   0 0   0   0   0   0   0   633 0   0   0   0   0   0   0   0   0   0   0   634 0   0   0   0   0   0   0  0   0 0   0 635 0   0   0   0   0 0   0
      0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0 636 0 0 0  0   0   0   0 0   0   0 0  637 0   0 0 0   0 0 0  0   0   0   0   638 0   0   0   0   0   0   0   0   0   0   0   639 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   640 0   0  0   0   0   0  0   0   0   0 0   641 0   0   0   0   0   0   0   0   0   0 0 642 0   0   0   0   0   0   0 0   0  0   0   643 0   0   0 0   0   0 0   0   0   0 0   0   0  0   0   0   0   0 0 0   0   0   0   0   0   0   0   644 0   0   0   0   0 0   0 0   0 0   0  645 0 0   0   0   0   0  0   0   0   0   0   646 0   0   0   0   0   0   0   0   0   0 0   647 0   0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0 0   0   0   0   0 0   0   0   0 0   648 0   0   0 0   0 0 0   0   0   0   0   649 0 0   0   0   0   0   0   0   0   0   0   650 0   0   0   0   0   0   0   0   0   0   0   651 0   0   0  0   0 0   0 0   0   0   0   0   0 0   0
      0   0   0   0   0   0   0   0   0   0   0   0   652 0   0   0   0   0   0 0 0   0 0 0  653 0   0   0 0   0   0 0  0   0   0 0 654 0 0 0  0   0   0   0   0   0   0   0   655 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   656 0   0   0   0   0   0  0   0   0   0  0   657 0   0  0   0   0   0 0   0   0   0   0   658 0   0   0   0   0   0 0 0   0   0   0   659 0   0   0 0   0  0   0   0   0   0   0 0   0   0 0   0   0   0 0   0   0  0   0   0   0   0 0 660 0   0   0   0   0   0   0   0   0   0   0   661 0 0   0 0   0 0   0  0   0 0   0   662 0   0  0   0   0   0   0   0   0   0   0   663 0   0   0   0   0   0 0   0   0   0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0 0   0   664 0   0 0   0   0   0 0   0   0   0   0 665 0 0 0   0   0   0   0   0   0 0   0   666 0   0   0   0   0   0   0   0   0   0   0   667 0   0   0   0   0   0   0   0   0   0   0  0   0 0   0 0   0   0   0   0   0 0   0
      0   0   0   0   668 0   0   0   0   0   0   0   0   0   0   0   669 0   0 0 0   0 0 0  0   0   0   0 670 0   0 0  0   0   0 0 0   0 0 0  671 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   672 0   0   0   0   0   0   0   0   0   0   0   673 0   0  0   0   0   0  0   0   0   0  0   674 0   0 0   0   0   0   0   0   0   0   0   675 0   0 0 0   0   0   0   0   0   0   0 0   0  0   0   0   0   0   0 0   0   0 0   0   0   0 0   676 0  0   0   0   0   0 0 0   0   0   0   677 0   0   0   0   0   0   0   0   0 0   0 678 0 0   0  0   0 0   0   0   0   0  0   679 0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0   0   0 0   0   0   0   0   0   0 0   0   680 0   0   0   0   0 0   0   0   0   0 0   681 0   0 0   0   0   0   0 0   0 0 0   682 0   0   0   0   0 0   0   0   0   0   0   683 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0 0   0 0   0   0   0   684 0 0   0
      0   0   0   0   0   0   0   0   685 0   0   0   0   0   0   0   0   0   0 0 686 0 0 0  0   0   0   0 0   0   0 0  687 0   0 0 0   0 0 0  0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   688 0   0   0   0   0   0   0   0   0   0   0   689 0   0   0   0   0   0   0   0   0   0  0   690 0   0  0   0   0   0  0   0   0   0 0   691 0   0   0   0   0   0   0   0   0   0 0 0   0   0   0   0   0   0   0 0   0  0   0   0   0   0   0 692 0   0 0   0   0   0 0   0   0  0   0   693 0   0 0 0   0   0   0   0   0   0   0   694 0   0   0   0   0 0   0 0   0 0   0  695 0 0   0   0   0   0  0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0   0   0 0   696 0   0   0   0   0 0   0   0   0   0   0   697 0 0   0   0   0   0 0   0   0   0 0   698 0   0   0 0   0 0 0   0   0   0   0   699 0 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  700 0 0   0 0   0   0   0   0   0 0   0
      701 0   0   0   0   0   0   0   0   0   0   0   702 0   0   0   0   0   0 0 0   0 0 0  703 0   0   0 0   0   0 0  0   0   0 0 0   0 0 0  0   0   0   0   0   0   0   0   0   0   0   0   704 0   0   0   0   0   0   0   0   0   0   0   705 0   0   0   0   0   0   0   0   0   0   0   706 0   0   0   0   0   0  0   0   0   0  0   707 0   0  0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0 0 0   0   0   0   0   0   0   0 708 0  0   0   0   0   0   0 0   0   0 0   709 0   0 0   0   0  0   0   0   0   0 0 710 0   0   0   0   0   0   0   0   0   0   0   711 0 0   0 0   0 0   0  0   0 0   0   0   0   0  0   0   0   0   0   0   0   0   0   0   0   0   0   712 0   0 0   0   0   0 0   0   0   0   0   713 0 0   0   0   0   0   0   0   0 0   0   714 0   0 0   0   0   0 0   0   0   0   0 715 0 0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   716 0   0   0   0   0   0   0  0   0 0   0 717 0   0   0   0   0 0   0
      0   0   0   0   718 0   0   0   0   0   0   0   0   0   0   0   719 0   0 0 0   0 0 0  0   0   0   0 0   0   0 0  0   0   0 0 0   0 0 0  0   0   0   0   720 0   0   0   0   0   0   0   0   0   0   0   721 0   0   0   0   0   0   0   0   0   0   0   722 0   0   0   0   0   0   0   0   0   0   0   723 0   0  0   0   0   0  0   0   0   0  0   0   0   0 0   0   0   0   0   0   0   0   0   0   0   0 0 724 0   0   0   0   0   0   0 0   0  0   0   725 0   0   0 0   0   0 0   0   0   0 0   726 0  0   0   0   0   0 0 0   0   0   0   727 0   0   0   0   0   0   0   0   0 0   0 0   0 0   0  0   0 0   0   0   0   0  0   0   0   0   0   728 0   0   0   0   0   0   0   0   0   0 0   729 0   0 0   0   0   0   0   0   0 0   0   730 0   0   0   0   0 0   0   0   0   0 0   731 0   0 0   0   0   0   0 0   0 0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0   0   0   732 0   0   0   0   0   0   0   0   0   0   0   733 0   0   0  0   0 0   0 0   0   0   0   734 0 0   0
      0   0   0   0   0   0   0   0   735 0   0   0   0   0   0   0   0   0   0 0 0   0 0 0  0   0   0   0 0   0   0 0  0   0   0 0 736 0 0 0  0   0   0   0   0   0   0   0   737 0   0   0   0   0   0   0   0   0   0   0   738 0   0   0   0   0   0   0   0   0   0   0   739 0   0   0   0   0   0   0   0   0   0  0   0   0   0  0   0   0   0  0   0   0   0 0   0   0   0   0   740 0   0   0   0   0   0 0 0   0   0   0   741 0   0   0 0   0  0   0   0   0   0   0 742 0   0 0   0   0   0 0   0   0  0   0   743 0   0 0 0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0 0   0 0   0  0   0 0   0   744 0   0  0   0   0   0   0   0   0   0   0   745 0   0   0   0   0   0 0   0   0   0 0   746 0   0   0   0   0 0   0   0   0   0   0   747 0 0   0   0   0   0 0   0   0   0 0   0   0   0   0 0   0 0 0   0   0   0   0   0   0 0   0   748 0   0   0   0   0   0   0   0   0   0   0   749 0   0   0   0   0   0   0   0   0   0   0  750 0 0   0 0   0   0   0   0   0 0   0
      751 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0 0   0 0 0  0   0   0   0 752 0   0 0  0   0   0 0 0   0 0 0  753 0   0   0   0   0   0   0   0   0   0   0   754 0   0   0   0   0   0   0   0   0   0   0   755 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0   0   0  0   0   0   0  0   756 0   0 0   0   0   0   0   0   0   0   0   757 0   0 0 0   0   0   0   0   0   0   0 758 0  0   0   0   0   0   0 0   0   0 0   759 0   0 0   0   0  0   0   0   0   0 0 0   0   0   0   0   0   0   0   0   0   0   0   0   0 0   0 760 0 0   0  0   0 0   0   0   0   0  0   761 0   0   0   0   0   0   0   0   0   0   0   762 0   0 0   0   0   0 0   0   0   0   0   763 0 0   0   0   0   0   0   0   0 0   0   0   0   0 0   0   0   0 0   0   0   0   0 0   0 0 0   764 0   0   0   0   0 0   0   0   0   0   0   765 0   0   0   0   0   0   0   0   0   0   0   766 0   0   0   0   0   0   0  0   0 0   0 767 0   0   0   0   0 0   0
      0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0 0 768 0 0 0  0   0   0   0 0   0   0 0  769 0   0 0 0   0 0 0  0   0   0   0   770 0   0   0   0   0   0   0   0   0   0   0   771 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   772 0   0  0   0   0   0  0   0   0   0 0   773 0   0   0   0   0   0   0   0   0   0 0 774 0   0   0   0   0   0   0 0   0  0   0   775 0   0   0 0   0   0 0   0   0   0 0   0   0  0   0   0   0   0 0 0   0   0   0   0   0   0   0   776 0   0   0   0   0 0   0 0   0 0   0  777 0 0   0   0   0   0  0   0   0   0   0   778 0   0   0   0   0   0   0   0   0   0 0   779 0   0 0   0   0   0   0   0   0 0   0   0   0   0   0   0   0 0   0   0   0   0 0   0   0   0 0   780 0   0   0 0   0 0 0   0   0   0   0   781 0 0   0   0   0   0   0   0   0   0   0   782 0   0   0   0   0   0   0   0   0   0   0   783 0   0   0  0   0 0   0 0   0   0   0   0   0 0   0
      0   0   0   0   0   0   0   0   0   0   0   0   784 0   0   0   0   0   0 0 0   0 0 0  785 0   0   0 0   0   0 0  0   0   0 0 0   0 0 0  0   786 0   787 0   0   0   0   0   0   0   0   0   788 0   0   0   0   0   0   0   0   0   0   0   789 790 0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0  0   0   0   0  791 0   0   0  0   0   0   0 0   0   0   0   0   0   0   0   0   0   792 0 0 0   0   0   0   0   0   0   0 0   0  0   0   793 794 0   0 0   0   0 0)))

(define-deferred ucd-canonical-cm-table-5
  #(#f  0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  45  46  47  48  49  50  51  52  53  54  55  56  57  58  59  60  61  62  63  64  65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80  81  82  83  84  85  86  87  88  89  90  91  92  93  94  95  96  97  98  99  100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246
    247 248 249 250 251 252 253 254 255 256 257 258 259 260 261 262 263 264 265 266 267 268 269 270 271 272 273 274 275 276 277 278 279 280 281 282 283 284 285 286 287 288 289 290 291 292 293 294 295 296 297 298 299 300 301 302 303 304 305 306 307 308 309 310 311 312 313 314 315 316 317 318 319 320 321 322 323 324 325 326 327 328 329 330 331 332 333 334 335 336 337 338 339 340 341 342 343 344 345 346 347 348 349 350 351 352 353 354 355 356 357 358 359 360 361 362 363 364 365 366 367 368 369 370 371 372 373 374 375 376 377 378 379 380 381 382 383 384 385 386 387 388 389 390 391 392 393 394 395 396 397 398 399 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 419 420 421 422 423 424 425 426 427 428 429 430 431 432 433 434 435 436 437 438 439 440 441 442 443 444 445 446 447 448 449 450 451 452 453 454 455 456 457 458 459 460 461 462 463 464 465 466 467 468 469 470 471 472 473 474 475 476 477 478 479 480 481 482 483 484 485 486 487 488 489 490 491 492 493 494
    495 496 497 498 499 500 501 502 503 504 505 506 507 508 509 510 511 512 513 514 515 516 517 518 519 520 521 522 523 524 525 526 527 528 529 530 531 532 533 534 535 536 537 538 539 540 541 542 543 544 545 546 547 548 549 550 551 552 553 554 555 556 557 558 559 560 561 562 563 564 565 566 567 568 569 570 571 572 573 574 575 576 577 578 579 580 581 582 583 584 585 586 587 588 589 590 591 592 593 594 595 596 597 598 599 600 601 602 603 604 605 606 607 608 609 610 611 612 613 614 615 616 617 618 619 620 621 622 623 624 625 626 627 628 629 630 631 632 633 634 635 636 637 638 639 640 641 642 643 644 645 646 647 648 649 650 651 652 653 654 655 656 657 658 659 660 661 662 663 664 665 666 667 668 669 670 671 672 673 674 675 676 677 678 679 680 681 682 683 684 685 686 687 688 689 690 691 692 693 694 695 696 697 698 699 700 701 702 703 704 705 706 707 708 709 710 711 712 713 714 715 716 717 718 719 720 721 722 723 724 725 726 727 728 729 730 731 732 733 734 735 736 737 738 739 740 741 742
    743 744 745 746 747 748 749 750 751 752 753 754 755 756 757 758 759 760 761 762 763 764 765 766 767 768 769 770 771 772 773 774 775 776 777 778 779 780 781 782 783 784 785 786 787 788 789 790 791 792 793))
