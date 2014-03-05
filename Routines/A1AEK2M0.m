A1AEK2M0 ; VEN/SMH - A1AEK2M Continuation;2014-03-05  1:34 PM
 ;;2.4;DHCP PATCH MODULE;;
 ;
 ; Conversion procedure from a VA PM HFS-extracted KIDS (complete):
 ;^TMP(28177,1,0)="Released TIU*1*241 SEQ #237" <-- $TXT prepended
 ;^TMP(28177,2,0)="Extracted from mail message" <-- this becomes the txt
 ;^TMP(28177,3,0)="**KIDS**:TIU*1.0*241^"       <-- $END TXT replaced
 ;^TMP(28177,4,0)="" --> becomes $KID append whatever is in 6
 ;^TMP(28177,5,0)="**INSTALL NAME**"
 ;^TMP(28177,6,0)="TIU*1.0*241"
 ;---
 ;^TMP(28177,1189,0)="**END**" --> becomes $END KID whatever is in 6
 ;^TMP(28177,1190,0)="**END**" --> DELETED
 ;
 ; A few random notes on various KIDS issues
 ; If the original is a mail message, it will looks like this
 ; 
 ; >> Released GMRA*4*44 SEQ #41
 ; >> Extracted from mail message
 ; >> **KIDS**:GMRA*4.0*44^
 ; >> 
 ; >> **INSTALL NAME** etc..
 ; >> kids contents
 ; >> **END**
 ; >> **END**
 ;
 ; If the original isn't a PM HFS-extracted KIDS build, but a Straight from 
 ; KIDS KIDS-build, then the KIDS first line looks like this:
 ;
 ; >> KIDS Distribution saved on Apr 30, 2013@05:31:47
 ; >> OR*371
 ; >> **KIDS**:OR*3.0*371^
 ; >> <blank line>
 ; >> **INSTALL NAME**
 ;
 ; Multibuilds look like this:
 ; 
 ; >> KIDS Distribution saved on Sep 23, 2011@17:42:57
 ; >> IB/PRCA Remedy Ticket Fixes
 ; >> **KIDS**:IB*2.0*459^PRCA*4.5*280^
 ; >> <blank line>
 ; >> **INSTALL NAME**
 ; >> text of first KIDS build
 ; >> **INSTALL NAME**
 ; >> text of second KIDS build
 ; >> **END**
 ; >> **END**
 ;
 ; A KIDS sent from another system via KIDS/MM has the following contents.
 ;$TXT Created by TESTMASTER,USER at VEN.SMH101.COM  (KIDS) on Thursday, 01/07/14 at 15:55
 ; <contents>
 ;$END TXT
 ;$KID ZZZ*1.0*1
 ;**INSTALL NAME**
 ; <contents>
 ;$END KID ZZZ*1.0*1
 ;
KIDFIL(ROOT,PATCH,TXTINFO,KIDGLO) ; $$; Private; Find the KIDS file that corresponds to a patch designation
 ; ROOT: Ref, File system roots (MP = Multibuild folder)
 ; PATCH: Val, Text file name
 ; TXTINFO: Ref, the analyzed Text array
 ; KIDGLO: Name, the Global into which to load the KIDS contents in PM format.
 ;
 ; This code is pretty iterative. It keeps trying different things until it finds the patch.
 ;
 N NOEXT S NOEXT=$P(PATCH,".",1,$L(PATCH,".")-1) ; no extension name
 N KIDFIL0 ; Trial iteration variable
 N DONE ; Loop exit
 ;
 ; Try by file name!
 N % F %="KID","kid","KIDS","kids","KIDs","kidS" D  Q:$G(DONE)
 . S KIDFIL0=NOEXT_"."_%
 . N POP
 . D OPEN^%ZISH("KID0",ROOT("SB"),KIDFIL0,"R")
 . I POP S KIDFIL0="" QUIT
 . D CLOSE^%ZISH("KID0")
 . ;
 . ; Okay. At this point we confirmed that the file exists. Is it right though?
 . K ^TMP($J,"TKID"),^("ANKID") ; Temp KID; Analysis KID
 . N % S %=$$FTG^%ZISH(ROOT("SB"),KIDFIL0,$NA(^TMP($J,"TKID",1,0)),3)   ; To Global
 . I '% S $EC=",U-FILE-DISAPPEARED,"
 . D ANALYZE^A1AEK2M1($NA(^TMP($J,"ANKID")),$NA(^TMP($J,"TKID"))) ; Analyze the file
 . ;
 . ; Now, make sure that the TXT file's designation is the same as the KIDS' patch no.
 . ; Loop through every patch in the file and make sure at least one matches.
 . N P S P=""
 . F  S P=$O(^TMP($J,"ANKID",P)) Q:P=""  I $$K2PMD^A1AEK2M(P)=TXTINFO("DESIGNATION") S DONE=1 QUIT
 . I $G(DONE) DO  QUIT
 . . M @KIDGLO=^TMP($J,"ANKID",P)
 . . D EN^DDIOL("Found patch "_TXTINFO("DESIGNATION")_" in "_KIDFIL0)
 ;
 ; If we don't have it, get all KIDS files and grab any one that has the
 ; patch number in its name.
 I $G(KIDFIL0)="" D  ; Still we don't have it.
 . N A S A("*.kid")="",A("*.KID")=""  ; Search for these files
 . S A("*.kid?")="",A("*.KID?")=""    ; and these too; but not the .json ones.
 . N FILES  ; rtn array by name
 . N % S %=$$LIST^%ZISH(ROOT("SB"),$NA(A),$NA(FILES)) ; ls
 . ; I '% S $EC=",U-DIRECTORY-DISAPPEARED," ; should never happen; WRONG: It's a possibility.
 . I '% QUIT  ; Try the multibuild directory next
 . K %,A ; bye
 . ;
 . N F S F="" ; file looper
 . N DONE ; control flag
 . ; here's the core search for the file name containing a patch number
 . ; Make sure that the patch doesn't contain spaces (package release)
 . F  S F=$O(FILES(F)) Q:F=""  I TXTINFO("DESIGNATION")'[" ",F[$P(TXTINFO("DESIGNATION"),"*",3) D  Q:$G(DONE)
 . . K ^TMP($J,"TKID"),^("ANKID") ; Temp KID; Analysis KID
 . . N % S %=$$FTG^%ZISH(ROOT("SB"),F,$NA(^TMP($J,"TKID",1,0)),3)   ; To Global
 . . I '% S $EC=",U-FILE-DISAPPEARED,"
 . . D ANALYZE^A1AEK2M1($NA(^TMP($J,"ANKID")),$NA(^TMP($J,"TKID"))) ; Analyze the file
 . . ;
 . . ; Now, make sure that the TXT file's designation is the same as the KIDS' patch no.
 . . ; Loop through every patch in the file and make sure at least one matches.
 . . N P S P=""
 . . F  S P=$O(^TMP($J,"ANKID",P)) Q:P=""  I $$K2PMD^A1AEK2M(P)=TXTINFO("DESIGNATION") S DONE=1 QUIT
 . . I $G(DONE) DO  QUIT
 . . . M @KIDGLO=^TMP($J,"ANKID",P)
 . . . D EN^DDIOL("Found patch "_TXTINFO("DESIGNATION")_" in "_F)
 . . . S KIDFIL0=F
 . ;
 . ; Patch zero special case (package release)
 . ; If true, analyze each file for the patch zero notation
 . I KIDFIL0="",(TXTINFO("DESIGNATION")'["*"!($P(TXTINFO("DESIGNATION"),"*",3)=0)) D
 . . N F S F=""
 . . F  S F=$O(FILES(F)) Q:F=""  D
 . . . K ^TMP($J,"TKID"),^("ANKID") ; Temp KID; Analysis KID
 . . . N % S %=$$FTG^%ZISH(ROOT("SB"),F,$NA(^TMP($J,"TKID",1,0)),3)   ; To Global
 . . . I '% S $EC=",U-FILE-DISAPPEARED,"
 . . . D ANALYZE^A1AEK2M1($NA(^TMP($J,"ANKID")),$NA(^TMP($J,"TKID"))) ; Analyze the file
 . . . N P S P=""
 . . . F  S P=$O(^TMP($J,"ANKID",P)) Q:P=""  I $$K2PMD^A1AEK2M(P)=$$K2PMD^A1AEK2M(TXTINFO("DESIGNATION")) S DONE=1 QUIT
 . . . I $G(DONE) DO  QUIT
 . . . . M @KIDGLO=^TMP($J,"ANKID",P)
 . . . . D EN^DDIOL("Found patch "_TXTINFO("DESIGNATION")_" in "_F)
 . . . . S KIDFIL0=F
 ;
 ; Now we have the hard case. We still don't have the file. 
 ; Let's look in the Multibuilds directory
 I $G(KIDFIL0)="" D
 . ; Set-up XTMP
 . ; NB: NO LOCKS B/C IT'S OKAY FOR MULTIPLE USERS TO FILE THIS SIMULTANEOUSLY
 . ; NB (CONT): THERE ARE NO COUNTERS WHICH NEED TO BE SYNCHRONIZED.
 . N XTMPS S XTMPS=$T(+0)
 . N START S START=$$NOW^XLFDT()
 . N PURGDT S PURGDT=$$FMADD^XLFDT(START,30)
 . S ^XTMP(XTMPS,0)=PURGDT_U_START_U_"Analyzed Multibuilds Holding Area"
 . ;
 . ; Load the Multibuild file names
 . N A S A("*.kid")="",A("*.KID")=""  ; Search for these files
 . S A("*.kid?")="",A("*.KID?")=""    ; and these too; but not the .json ones.
 . N FILES  ; rtn array by name
 . N % S %=$$LIST^%ZISH(ROOT("MB"),$NA(A),$NA(FILES)) ; ls
 . I '% S $EC=",U-DIRECTORY-DISAPPEARED," ; should never happen
 . K %,A ; bye
 . ;
 . N F S F="" ; file looper
 . N DONE ; control flag
 . ; Analyze each Multibuild
 . F  S F=$O(FILES(F)) Q:F=""  D  Q:$G(DONE)
 . . D EN^DDIOL("Analyzing Multibuild file "_F) ; print out
 . . I '$D(^XTMP(XTMPS,F)) D  ; If it isn't loaded already...
 . . . K ^TMP($J,"TKID"),^("ANKID") ; Temp KID; Analysis KID
 . . . N % S %=$$FTG^%ZISH(ROOT("MB"),F,$NA(^TMP($J,"TKID",1,0)),3)   ; To Global
 . . . I '% S $EC=",U-FILE-DISAPPEARED,"
 . . . D ANALYZE^A1AEK2M1($NA(^TMP($J,"ANKID")),$NA(^TMP($J,"TKID"))) ; Analyze the file
 . . . M ^XTMP(XTMPS,F)=^TMP($J,"ANKID") ; Put into XTMP
 . . ; Now, make sure that the TXT file's designation is the same as the KIDS' patch no.
 . . ; Loop through every patch in the file and make sure at least one matches.
 . . N P S P=""
 . . F  S P=$O(^XTMP(XTMPS,F,P)) Q:P=""  I $$K2PMD^A1AEK2M(P)=TXTINFO("DESIGNATION") S DONE=1 QUIT
 . . I $G(DONE) D  QUIT
 . . . M @KIDGLO=^XTMP(XTMPS,F,P)
 . . . D EN^DDIOL("Found patch "_TXTINFO("DESIGNATION")_" in "_F)
 . . . S KIDFIL0=F
 ;
 ; If we still can't find it. Oh well! Can't do nuthin.
 K ^TMP($J,"TKID"),^("ANKID")
 QUIT $G(KIDFIL0)
 ;
GETSTRM(DESIGNATION) ; Private to package; $$; Get the Stream for a designation using a patch number
 ; Input: DESIGNATION XXX*1.0*5
 ; Output: Stream IEN in 11007.1
 N PN
 I $L(DESIGNATION,"*")>1 S PN=$P(DESIGNATION,"*",3)
 E  S PN=0
 I PN=0 QUIT 1  ; VA Patch Stream
 N STRM
 N I F I=0:0 S I=$O(^A1AE(11007.1,I)) Q:'I  D  Q:$G(STRM)
 . N MIN S MIN=I-1 ; For Patch zero (e.g. package release XOBV*1.6*0)
 . N MAX S MAX=I+998 ; up to 999
 . I PN'<MIN&(PN'>MAX) S STRM=I  ; Really this is IF MIN<=PN<=MAX...
 Q STRM
 ;
SELFILQ ; Public; Interactive entry point... ; TODO
 ; This code is a NO-OP right now.
 ; I probably would use it in the future, but not now.
 ; ZEXCEPT: ROOT,PATCH
 N KIDFIL
 N ARRAY S ARRAY("*.KI*")="",ARRAY("*.ki*")=""
 N FILE
 N Y S Y=$$LIST^%ZISH(ROOT("SB"),$NA(ARRAY),$NA(FILE))
 I 'Y  ; TODO!!! -- probably ask the user to try again since directory has no KIDS files.
 S KIDFIL=$$SELFIL(.FILE,,"Select a KIDS build to match to "_PATCH)
 QUIT KIDFIL
 ;
SELFIL(FILES,EXTFILTER,DIRA) ; Public; INTERACTIVE ; Select a file from a list
 ; FILES = Ref List of files from LIST^%ZISH
 ; EXTFILTER = Val .TXT or so
 ; DIRA = Val What to ask the user for
 ; Uses fileman calls to ease the pain of selecting stuff.
 ;
 N I S I=""
 ; Filter away using the extension
 I $L($G(EXTFILTER)) F  S I=$O(FILES(I)) Q:I=""  D
 . I $E($RE(I),1,$L(EXTFILTER))'=$RE(EXTFILTER) K FILES(I)
 ;
 ; If no files left, quit with an empty string
 Q:'$L($O(FILES(""))) ""
 ;
 ; Create a global for DIR/DIC
 K ^TMP($J,"FILES")
 S ^TMP($J,"FILES",0)="File List"
 N CNT S CNT=1
 F  S I=$O(FILES(I)) Q:I=""  S ^TMP($J,"FILES",CNT,0)=I,CNT=CNT+1
 ;
 ; Index
 N DIK,DA S DIK="^TMP($J,""FILES""," D IXALL^DIK
 ; Select
 N DIR,X,Y,DIROUT,DIRUT,DTOUT,DUOUT,DIROUT
 S DIR(0)="P^TMP($J,""FILES"",",DIR("A")=$G(DIRA,"Select a file from the list") D ^DIR
 ; Bye
 K ^TMP($J,"FILES")
 ;
 I $L(Y,U)=2 Q $P(Y,U,2)
 E  QUIT ""
 ;
CLEANHF(MSGGLO) ; Private... Clean header and footer in message global
 ; WARNING - Naked all over inside the do block.
 N S S S=$O(@MSGGLO@("")) ; first numeric sub.
 I @MSGGLO@(S,0)'["$TXT Created by " D
 . ; First line is invalid. Try various patterns.
 . N I F I=1:1 N PATT S PATT=$T(CLNPATT+I),PATT=$P(PATT,";;",2) Q:($$TRIM^XLFSTR(PATT)=">>END<<")  D
 . . I $$TRIM^XLFSTR(^(0))=$$TRIM^XLFSTR(PATT) S ^(0)="$TXT Created by UNKNOWN,UNKNOWN at DOWNLOADS.VA.GOV  (KIDS)"
 . ; If still not there, put in first node before the message.
 . I ^(0)'["$TXT Created by " S @MSGGLO@(S-1,0)="$TXT Created by UNKNOWN,UNKNOWN at DOWNLOADS.VA.GOV  (KIDS)"
 ;
 N LASTSUB S LASTSUB=$O(@MSGGLO@(" "),-1)
 I @MSGGLO@(LASTSUB,0)'["$END TXT" S @MSGGLO@(LASTSUB+1,0)="$END TXT"
 QUIT
 ;
CLNPATT ;; Headers to substitute if present using a contains operator. 1st one is just a blank -- INTENTIONAL
 ;;
 ;;*********************
 ;;Original message:
 ;;This informational patch
 ;;>>END<<
 ;
ADDPATCH(A1AEPKIF,A1AEVR,TXTINFO,PATCHMSG,KIDMISSING,INFOONLY) ; Private $$ ; Add patch to 11005
 ; Input: TBD
 ; Non-importing version is at NUM^A1AEUTL
 N DESIGNATION S DESIGNATION=TXTINFO("DESIGNATION")
 ;
 ; Don't add a patch if it already exists in the system
 ; This first code is for derived patches
 I $D(TXTINFO("ORIG-DESIGNATION")),$D(^A1AE(11005,"ADERIVED",TXTINFO("ORIG-DESIGNATION"))) DO  QUIT $O(^(TXTINFO("ORIG-DESIGNATION"),""))
 . D EN^DDIOL($$RED^A1AEK2M1("Patch already exists. Not adding again."))
 . S A1AENB=$P(DESIGNATION,"*",3) ; leak this
 . S A1AEPD=DESIGNATION ; and also this
 ;
 ; This code is for original patches (not derived)
 I '$D(TXTINFO("ORIG-DESIGNATION")),$D(^A1AE(11005,"B",DESIGNATION)) DO  QUIT $O(^(DESIGNATION,""))
 . D EN^DDIOL($$RED^A1AEK2M1("Patch already exists. Not adding again."))
 . S A1AENB=$P(DESIGNATION,"*",3) ; leak this
 . S A1AEPD=DESIGNATION ; and also this
 ;
 ; This block adds the entry to 11005 using the SETNUM API.
 N X S X=DESIGNATION
 S A1AENB=$P(DESIGNATION,"*",3) ; ZEXCEPT: A1AENB leak this
 N A1AETY S A1AETY="PH"
 N A1AEFL S A1AEFL=11005
 N DIC,Y S DIC(0)="LX" ; Laygo, Exact match
 ; ZEXCEPT: DA,A1AEPD Leaked by A1AEUTL
 I $D(TXTINFO("ORIG-DESIGNATION")) D  ; Derived patch!!
 . D SETNUM^A1AEUTL   ; This adds the patch based on the latest patch number
 . N FDA S FDA(11005,DA_",",5.2)=TXTINFO("ORIG-DESIGNATION")                ; Derived from patch field
 . N DIERR D FILE^DIE("E",$NA(FDA)) I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"   ; File--external b/c this is a pointer.
 E  D SETNUM1^A1AEUTL ; This forces the current patch number in. 
 ;
 ; Lock the record
 LOCK +^A1AE(11005,DA):0 E  S $EC=",U-FAILED-TO-LOCK," ; should never happen
 ;
 ; Put stream
 N STREAM S STREAM=$$GETSTRM^A1AEK2M0(DESIGNATION) ; PATCH STREAM
 N FDA S FDA(11005,DA_",",.2)=STREAM
 N DIERR
 D FILE^DIE("",$NA(FDA),$NA(ERR))
 I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"
 ;
 ; Change status to Under Development and add developer in
 ; TODO: If we have time, do this the proper way with Fileman APIs.
 S $P(^A1AE(11005,DA,0),U,8)="u"
 ;
 ; Get developer
 N DEV
 N NAME S NAME=TXTINFO("DEV")
 D STDNAME^XLFNAME(.NAME) ; Remove funny stuff (like dots at the end)
 S DEV=$$FIND1^DIC(200,"","QX",NAME,"B") ; Get developer
 ;
 D ASSERT(DEV,"Developer "_TXTINFO("DEV")_" couldn't be resolved")
 ;
 S $P(^A1AE(11005,DA,0),U,9)=DEV
 ; File Date
 N X,Y S X=TXTINFO("DEV","DATE") D ^%DT
 S $P(^A1AE(11005,DA,0),U,12)=Y
 ; Hand cross-reference
 S ^A1AE(11005,"AS",A1AEPKIF,A1AEVR,"u",A1AENB,DA)=""
 ;
 ; Add subject and priority and a default and sequenece number
 N FDA,IENS
 N DIERR
 S IENS=DA_","
 S FDA(11005,IENS,"PATCH SUBJECT")=TXTINFO("SUBJECT")
 S FDA(11005,IENS,"PRIORITY")=TXTINFO("PRIORITY")
 S FDA(11005,IENS,"DISPLAY ROUTINE PATCH LIST")="Yes"
 D FILE^DIE("E",$NA(FDA)) I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"
 I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"
 ;
 ; Get Categories from DD (abstractable function; maybe do that)
 N CATDD D FIELD^DID(11005.05,.01,,"POINTER",$NA(CATDD))  ; Categories DD
 N CATS ; Categories
 ; d:DATA DICTIONARY;i:INPUT TEMPLATE;
 N I F I=1:1:$L(CATDD("POINTER"),";") D        ; for each
 . N CATIE S CATIE=$P(CATDD("POINTER"),";",I)  ; each
 . Q:CATIE=""                                  ; last piece is empty. Make sure we aren't tripped up.
 . N EXT,INT                                   ; External Internal forms
 . S INT=$P(CATIE,":"),EXT=$P(CATIE,":",2)     ; get these
 . S CATS(EXT)=INT                             ; set into array for use below
 K CATDD
 ;
 N FDA
 N I F I=1:1 Q:'$D(TXTINFO("CAT",I))  D        ; for each
 . N CAT S CAT=TXTINFO("CAT",I)                ; each
 . S CAT=$$UP^XLFSTR(CAT)                      ; uppercase. PM Title cases them.
 . I CAT["ENHANCE" S CAT=$P(CAT," ")           ; Remove parens from 'Enhancement (Mandatory)'
 . N INTCAT S INTCAT=CATS(CAT)                 ; Internal Category
 . S FDA(11005.05,"+"_I_","_IENS,.01)=INTCAT   ; Addition FDA
 N DIERR                                       ; Fileman error flag
 D UPDATE^DIE("",$NA(FDA),$NA(ERR))            ; Add data
 I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"         ; Chk for error
 D ASSERT($O(^A1AE(11005,+IENS,"C",0)))        ; Assert that there is at least one.
 K FDA
 K CATS                                        ; don't need this anymore
 ;
 ; Add Description to the patch
 ; Reference code is COPY^A1AECOPD, but this time we use Fileman
 ;
 ; Now put in the whole WP field in the file.
 N DIERR
 D WP^DIE(11005,IENS,5.5,"",$NA(TXTINFO("DESC")),$NA(ERR))
 I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"         ; Chk for error
 D ASSERT($O(^A1AE(11005,DA,"D",0))>0) ; Assert that it was copied into PATCH DESCRIPTION
 ;
 ; Now, load the full KIDS build
 ; Reference code: ^A1AEM1
 ;
 ; 1st Create stub entry in 11005.1, whether or not we have KIDS file to populate
 NEW DIC,X,DINUM,DD,DO,DE,DQ,DR
 S DIC(0)="L"
 S (X,DINUM)=DA,DIC="^A1AE(11005.1,",DIC("DR")="20///"_"No routines included" K DD,DO D FILE^DICN K DE,DQ,DR,DIC("DR")
 ;
 ; Now load either the KIDS file or the HFS data from the remote system that was sent to us
 I 'INFOONLY D                            ; Must be a patch with KIDS contents
 . I KIDMISSING D HFS2^A1AEM1(DA)         ; No KIDS file found ; NB: Deletes 2 node (field 20) on 11005.1
 . E  D                                   ; We have a KIDS file
 . . S $P(^A1AE(11005.1,DA,0),"^",11)="K" ; FND+19  ; Type of message is KIDS not DIFROM
 . . K ^A1AE(11005.1,DA,2)                ; TRASH+7 ; remove old KIDS build
 . . MERGE ^A1AE(11005.1,DA,2)=@PATCHMSG  ; FND+23  ; Load the new one in.
 . . N X,Y S X=TXTINFO("DEV","DATE") D ^%DT         ; Get developer send date
 . . S $P(^A1AE(11005.1,DA,2,0),"^",5)=Y  ; FND+29  ; ditto
 . . S $P(^A1AE(11005.1,DA,2,0),"^",2)="" ; FND+30  ; Message IEN; We didn't load this from Mailman
 . . S $P(^A1AE(11005.1,DA,2,0),"^",3)="" ; FND+31  ; Message date; ditto
 . . D RTNBLD^A1AEM1(DA)                  ; FND+32  ; Load the routine information into 11005 from KIDS message
 . . ; if we load KIDS get rid of HFS "shadow" copy of the KIDS
 . . I $D(^A1AE(11005.5,DA,0)) N DIK S DIK="^A1AE(11005.5," D ^DIK ; FND+34
 ;
 ; Assertions
 N HASRTN S HASRTN=0 ; Has Routines?
 N I F I=1:1 Q:'$D(TXTINFO("CAT",I))  I TXTINFO("CAT",I)="Routine" S HASRTN=1  ; oh yes it does
 I HASRTN,'KIDMISSING D ASSERT($O(^A1AE(11005,DA,"P",0)),"Patch says routine must be present") ; Routine information in Patch
 I 'KIDMISSING D ASSERT($O(^A1AE(11005.1,DA,2,0)),"11005.1 entry must exist for each loaded patch")
 ;
 ; Now, complete and verify the patch, but don't run the input transforms b/c they send mail messages
 ; NB: B/c of the Daisy chain triggers, the current DUZ and date will be used for users. 
 ; NB (cont): I will fix this in a sec.
 N N F N="COM","VER" D
 . N DUZ
 . N NAME S NAME=TXTINFO(N)
 . D STDNAME^XLFNAME(.NAME) ; Remove funny stuff (like dots at the end)
 . S DUZ=$$FIND1^DIC(200,"","QX",NAME,"B") ; Get developer
 . D ASSERT(DUZ,"User "_NAME_" couldn't be resolved")
 . N FDA,DIERR
 . I N="COM" S FDA(11005,IENS,8)="c" D FILE^DIE("",$NA(FDA)) I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"
 . I N="VER" S FDA(11005,IENS,8)="v" D FILE^DIE("",$NA(FDA)) I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"
 . N X,Y S X=TXTINFO(N,"DATE") D ^%DT
 . N FDA,DIERR
 . S FDA(11005,IENS,$S(N="COM":10,1:11))=Y ; 10=DATE PATCH COMPLETED; 11=DATE PATCH VERIFIED
 . D FILE^DIE("",$NA(FDA)) I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"
 ;
 ; Now, put the patches into a review status
 N FDA,DIERR S FDA(11005,IENS,8)="2r" D FILE^DIE("",$NA(FDA)) I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"
 ;
 ; Now keep associated patches for later filing in a holding area
 ; No locks necessary since no increments used.
 N XTMPS S XTMPS=$T(+0)_"-ASSOCIATED-PATCHES"        ; Namespaced Sub in ^XTMP
 N START S START=$$NOW^XLFDT()                       ; Now
 N PURGDT S PURGDT=$$FMADD^XLFDT(START,365.24*2+1\1) ; Hold for two years
 S ^XTMP(XTMPS,0)=PURGDT_U_START_U_"Associated Patches Holding Area"
 N I F I=1:1 Q:'$D(TXTINFO("PREREQ",I))  S ^XTMP(XTMPS,DESIGNATION,TXTINFO("PREREQ",I))=""
 ;
 ;
 ; Sequence number (only for VA patches and real patches not package releases)
 N FDA,DIERR
 I STREAM=1,$P(DESIGNATION,"*",3)'=0 S FDA(11005,IENS,"SEQUENTIAL RELEASE NUMBER")=TXTINFO("SEQ") ; Only file for VA patches
 D:$D(FDA) FILE^DIE("E",$NA(FDA)) I $D(DIERR) S $EC=",U-FILEMAN-ERROR,"
 ;
 LOCK -^A1AE(11005,DA)
 QUIT DA
 ;
ASSERT(X,Y) ; Assertion engine
 ; ZEXCEPT: XTMUNIT - Newed on a lower level of the stack if using M-Unit
 ; I X="" BREAK
 I $D(XTMUNIT) D CHKTF^XTMUNIT(X,$G(Y)) QUIT  ; if we are inside M-Unit, assert using that engine.
 I 'X D EN^DDIOL($G(Y)) S $EC=",U-ASSERTION-ERROR,"  ; otherwise, throw error if assertion fails.
 QUIT