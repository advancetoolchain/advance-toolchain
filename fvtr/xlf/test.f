! Copyright 2017 IBM Corporation
!
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
!    http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.

      PROGRAM CMPLXD
        IMPLICIT COMPLEX(X)
        PARAMETER (PI = 3.141592653589793, XJ = (0, 1))
        DO 1, I = 0, 7
          X = EXP(XJ * I * PI / 4)
          IF (AIMAG(X).LT.0) THEN
            PRINT 2, 'e**(j*', I, '*pi/4) = ', REAL(X), ' - j',-AIMAG(X)
          ELSE
            PRINT 2, 'e**(j*', I, '*pi/4) = ', REAL(X), ' + j', AIMAG(X)
          END IF
    2     FORMAT (A, I1, A, F10.7, A, F9.7)
    1     CONTINUE
        STOP
      END
