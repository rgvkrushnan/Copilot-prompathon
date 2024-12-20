Optimized COBOL Program (CONVERTFB)
IDENTIFICATION DIVISION.
PROGRAM-ID. CONVERTFB.
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT INFILE ASSIGN TO 'INPUT.VB.DATASET'
        ORGANIZATION IS SEQUENTIAL.
    SELECT OUTFILE ASSIGN TO 'OUTPUT.FB.DATASET'
        ORGANIZATION IS SEQUENTIAL.
    SELECT RESTARTFILE ASSIGN TO 'RESTART.TABLE'
        ORGANIZATION IS SEQUENTIAL.
    SELECT REPORTFILE ASSIGN TO 'REPORT.DATASET'
        ORGANIZATION IS SEQUENTIAL.

DATA DIVISION.
FILE SECTION.
FD  INFILE
    RECORDING MODE IS V
    BLOCK CONTAINS 0 RECORDS
    RECORD CONTAINS 0 TO 32756 CHARACTERS
    LABEL RECORDS ARE STANDARD
    DATA RECORD IS IN-REC.

01  IN-REC.
    05  IN-LENGTH      PIC S9(4) COMP.
    05  IN-DATA        PIC X(32756).

FD  OUTFILE
    RECORDING MODE IS F
    BLOCK CONTAINS 0 RECORDS
    RECORD CONTAINS 80 CHARACTERS
    LABEL RECORDS ARE STANDARD
    DATA RECORD IS OUT-REC.

01  OUT-REC           PIC X(80).

FD  RESTARTFILE
    RECORDING MODE IS F
    BLOCK CONTAINS 0 RECORDS
    RECORD CONTAINS 80 CHARACTERS
    LABEL RECORDS ARE STANDARD
    DATA RECORD IS RESTART-REC.

01  RESTART-REC.
    05  RESTART-COUNTER PIC 9(8).

FD  REPORTFILE
    RECORDING MODE IS F
    BLOCK CONTAINS 0 RECORDS
    RECORD CONTAINS 80 CHARACTERS
    LABEL RECORDS ARE STANDARD
    DATA RECORD IS REPORT-REC.

01  REPORT-REC        PIC X(80).

WORKING-STORAGE SECTION.
01  WS-COUNTER        PIC 9(8) VALUE 0.
01  WS-LIMIT          PIC 9(8) VALUE 99999999.
01  WS-TEMP-VAR       PIC 9(8) VALUE 0.
01  WS-RESTART        PIC 9(8) VALUE 0.
01  WS-TOTAL-RECORDS  PIC 9(8) VALUE 0.
01  WS-NAME           PIC X(30).
01  WS-ACCOUNT-NUMBER PIC X(10).
01  WS-TIMESTAMP      PIC X(20).
01  WS-TRANSACTION-AMOUNT PIC S9(9)V99.
01  WS-LAST-NAME      PIC X(30).
01  WS-LAST-ACCOUNT-NUMBER PIC X(10).
01  WS-LAST-TRANSACTION-AMOUNT PIC S9(9)V99.
01  WS-LAST-TIMESTAMP PIC X(20).
01  WS-ADJUSTED-AMOUNT PIC S9(9)V99.
01  WS-EOF            PIC X VALUE 'N'.

PROCEDURE DIVISION.
MAIN-PARA.
    OPEN INPUT INFILE
    OPEN OUTPUT OUTFILE
    OPEN I-O RESTARTFILE
    OPEN OUTPUT REPORTFILE
    PERFORM INIT-RESTART
    PERFORM UNTIL WS-EOF = 'Y'
        PERFORM READ-AND-CONVERT
        IF WS-EOF = 'N'
            ADD 1 TO WS-COUNTER
            ADD 1 TO WS-TOTAL-RECORDS
            PERFORM UPDATE-RESTART
        END-IF
    END-PERFORM
    PERFORM REPORT-PARA
    CLOSE INFILE
    CLOSE OUTFILE
    CLOSE RESTARTFILE
    CLOSE REPORTFILE
    STOP RUN.

INIT-RESTART.
    READ RESTARTFILE INTO RESTART-REC
        AT END
            MOVE 0 TO WS-RESTART
        NOT AT END
            MOVE RESTART-COUNTER TO WS-RESTART
    END-READ
    MOVE WS-RESTART TO WS-COUNTER.

READ-AND-CONVERT.
    READ INFILE INTO IN-REC
        AT END
            MOVE 'Y' TO WS-EOF
        NOT AT END
            MOVE IN-DATA(1:30) TO WS-NAME
            MOVE IN-DATA(31:10) TO WS-ACCOUNT-NUMBER
            MOVE IN-DATA(41:20) TO WS-TIMESTAMP
            MOVE IN-DATA(61:10) TO WS-TRANSACTION-AMOUNT
            IF WS-NAME = WS-LAST-NAME AND WS-ACCOUNT-NUMBER = WS-LAST-ACCOUNT-NUMBER
                IF WS-TRANSACTION-AMOUNT < 0 AND WS-LAST-TRANSACTION-AMOUNT < 0
                    ADD WS-TRANSACTION-AMOUNT TO WS-LAST-TRANSACTION-AMOUNT
                    MOVE WS-LAST-TRANSACTION-AMOUNT TO WS-ADJUSTED-AMOUNT
                    PERFORM REPORT-REVERSAL
                ELSE IF WS-TRANSACTION-AMOUNT > 0 AND WS-LAST-TRANSACTION-AMOUNT > 0
                    ADD WS-TRANSACTION-AMOUNT TO WS-LAST-TRANSACTION-AMOUNT
                    MOVE WS-LAST-TRANSACTION-AMOUNT TO WS-ADJUSTED-AMOUNT
                    PERFORM REPORT-REVERSAL
                END-IF
            ELSE
                MOVE WS-TRANSACTION-AMOUNT TO WS-ADJUSTED-AMOUNT
            END-IF
            MOVE IN-DATA(1:80) TO OUT-REC
            WRITE OUT-REC
            MOVE WS-NAME TO WS-LAST-NAME
            MOVE WS-ACCOUNT-NUMBER TO WS-LAST-ACCOUNT-NUMBER
            MOVE WS-TRANSACTION-AMOUNT TO WS-LAST-TRANSACTION-AMOUNT
            MOVE WS-TIMESTAMP TO WS-LAST-TIMESTAMP
    END-READ.

UPDATE-RESTART.
    MOVE WS-COUNTER TO RESTART-COUNTER
    REWRITE RESTART-REC.

REPORT-REVERSAL.
    MOVE 'REVERSAL: ' TO REPORT-REC(1:10)
    MOVE WS-NAME TO REPORT-REC(11:40)
    MOVE WS-ACCOUNT-NUMBER TO REPORT-REC(41:50)
    MOVE WS-TIMESTAMP TO REPORT-REC(51:70)
    MOVE WS-ADJUSTED-AMOUNT TO REPORT-REC(71:80)
    WRITE REPORT-REC.

REPORT-PARA.
    MOVE 'TOTAL RECORDS: ' TO REPORT-REC(1:15)
    MOVE WS-TOTAL-RECORDS TO REPORT-REC(16:23)
    WRITE REPORT-REC
    MOVE 'LAST TIMESTAMP: ' TO REPORT-REC(1:15)
    MOVE WS-LAST-TIMESTAMP TO REPORT-REC(16:35)
    WRITE REPORT-REC.
