%INCLUDE '\\jennair\defects\include\LIBNAMEs.sas';

libname defdata  server=henman.shr1;
libname defdataa server=henman.shr1;
libname defdatas server=henman.shr1;
libname defshrs  server=henman.shr5;


/* Use this for test server */
/* LIBNAME defdata  SERVER=foghorn.shr1; */
/* LIBNAME defdataa SERVER=foghorn.shr1; */
/* LIBNAME defdatas SERVER=foghorn.shr1; */
/* LIBNAME defshrs  SERVER=foghorn.shr5; */


/* Initial data step to get helena's defectid's from the whole defect table */
DATA defects;
	SET defdatas.defects(RENAME = (title = mixedcase_title cmponent = component reptdate = creation_date 
	updtdate = update_date updttime = update_time uia_issue = ui_affected linksflg = links_flag));
	BY defectid;
	
	WHERE reptid = 'PEARCE, H.' OR reptid = 'HUFFMAN, C.' ;
	
	creation_datetime = DHMS(creation_date,0,0,0);
	FORMAT creation_datetime datetime16.;
	
	/* Unchanged variables from defects table */
	KEEP defectid reptid mixedcase_title product component priority creation_date creation_datetime keywords 
	     ui_affected pub_issue open openloc closeloc links_flag;
RUN;


/* Second data step to merge all of the related information from history and link table by defectid */
DATA full_data;
	/* Variables to keep consistent throughout this data step */
	RETAIN defectid reptid mixedcase_title product component priority creation_date lasthistory_datetime lasthistory_date 
	completion_time keywords ui_affected pub_issue open openloc closeloc links_flag;
	
	/* Changing the length of specific variables */
	LENGTH priority $7 ui_affected $20 pub_issue $8 open $3 links_flag $3 status_collection $300 linktype_collection $300 link_collection $300 
	location_collection $300 linktime_collection $300 track_collection $300 platform_collection $300 history_collection $300 tsnumber_collection $300 ;
	
	/* DO step to go through each defectid in helena_defects and match THEN merge them to id's in history and links table */
	DO item = 1 BY 1 UNTIL( last.defectid );
		MERGE defdatas.history(RENAME = (DEFECTID = defectid LOCATION = current_location PLATFORM = current_platform TRACK = current_track 
		status = current_status WHEN = lasthistory_datetime)) defects(IN = indefects) defdata.links (RENAME = (WHEN = link_time)) defdatas.tsnumbers (RENAME = (TSNUMBER = current_tsnumber));
		BY defectid;
		IF indefects;
	
	/* While merging the tables, keep track and store of all past info of the current defect in collections */
		IF ((FIND(history_collection, lasthistory_datetime)  = 0) AND (FIND(status_collection, current_status) = 0)) THEN 
 			DO;
 			history_collection = CATX( ', ', history_collection, lasthistory_datetime);
			status_collection = CATX( ', ', status_collection, current_status );
			END;
		
		linktime_collection = CATX( ', ', linktime_collection, link_time);
		
		IF ((FIND(linktime_collection, link_time))  = 0 AND (FIND(link_collection, link) = 0)) THEN
			DO;	
			linktype_collection = CATX( ', ', linktype_collection, linktype );
			link_collection = CATX( ', ', link_collection, link );
			END;
		
		/* Create Location Collection by concatenating all unique values of current_location within history table */
		IF (FIND(location_collection, current_location ) = 0) THEN location_collection = CATX( ', ', location_collection, current_location);
		
		/* Create Track Collection by concatenating all unique values of current_track within history table */
		IF (FIND(track_collection, current_track) = 0) THEN track_collection = CATX( ', ', track_collection, current_track);
		
		/* Create Platform Collection by concatenating all unique values of current_platform within history table */
		IF (FIND(platform_collection, current_platform) = 0) THEN platform_collection = CATX( ', ', platform_collection, current_platform);
		
		IF (FIND(tsnumber_collection, current_tsnumber) = 0) THEN tsnumber_collection = CATX( ', ', tsnumber_collection, current_tsnumber);
	END; 

/* Data Cleansing */
	lasthistory_date = DATEPART(lasthistory_datetime);
	FORMAT lasthistory_date DATE7.;
	completion_time = INTCK('DAYS', creation_date, lasthistory_date, 'C');
	
	/* If the defect is still open change completion time to -1 */
	IF open = 'Y' THEN completion_time = -1;

	/* Calculated Variables */
	num_defer = COUNT(status_collection, "DEFER");
	num_dupto = COUNT(linktype_collection, "DUP TO");
	num_dupfrom = COUNT(linktype_collection, "FROM");
	num_blocking = COUNT(linktype_collection, "BLOCKING");
	num_blockedby = COUNT(linktype_collection, "BLOCKED BY");
	relations = COUNT(linktype_collection, "RELATED TO");
	num_links = 1 + COUNT(linktype_collection, ",");
	num_keywords = 1 + COUNT(Keywords, " "); 
	status_changes = COUNT(status_collection, ",");
	location_changes = COUNT(location_collection, ",");
	track_changes = COUNT(track_collection, ",");
	IF MISSING(tsnumber_collection) THEN num_tsnumber = 0;
	ELSE IF COUNT(tsnumber_collection, ",") > 0 THEN num_tsnumber = COUNT(tsnumber_collection, ",");
	ELSE num_tsnumber = 1;
	
/* 	IF (num_dupto > 0) THEN DO; */
/* 	dup_fixed = 1; */
/* 		DO i=1 TO num_dupto; */
/* 		current_dup = SCAN(dup_collection,i,', ','M'); */
/* 			DO item = 1 BY 1 UNTIL( last.defectid ); */
/* 			IF(current_dup = defectid) AND ((FIND(closeloc, "FIXED") = 0 OR (FIND(closeloc, "NOBUG") = 0))) then dup_fixed = 0; */
/* 			END; */
/* 		END; */
/* 	END; */

	IF (((FIND(closeloc, "FIXED") = 0) AND (FIND(closeloc, "NOBUG") = 0)) OR Open = "Y") 
	OR ((FIND(closeloc, "NOFIX") ~= 0) AND (FIND(closeloc, "FIXED") = 0))
	then virulence = 1 + num_dupfrom + (2 * num_blocking) + (8 * num_tsnumber);
	ELSE virulence = 0;
	age = INTCK('DAYS', creation_date,TODAY(),'C');
	
	/* Capitalization */
	reptid = PROPCASE(reptid);
	current_status = PROPCASE(current_status);
	status_collection = PROPCASE(status_collection, ", ");
	linktype_collection = PROPCASE(linktype_collection, ", ");
	
	/* Remove abbreviations in columns to improve readability */
	priority = TRANWRD(priority, 'A', 'Alert'); priority = TRANWRD(priority, 'H', 'High');
	priority = TRANWRD(priority, 'M', 'Medium');priority = TRANWRD(priority, 'L', 'Low');
	
	ui_affected = TRANWRD(ui_affected, 'C', 'Completed'); ui_affected = TRANWRD(ui_affected, 'I', 'UI Inconsistency');
	ui_affected = TRANWRD(ui_affected, 'N', 'UI Not Affected'); ui_affected = TRANWRD(ui_affected, 'P', 'In Progress');
	ui_affected = TRANWRD(ui_affected, 'R', 'Reviewing'); ui_affected = TRANWRD(ui_affected, 'U', 'Unknown UI Effect');
	ui_affected = TRANWRD(ui_affected, 'Y', 'UI Affected');
	
	pub_issue = TRANWRD(pub_issue, 'D', 'Deferred'); pub_issue = TRANWRD(pub_issue, 'F', 'Fixed');
	pub_issue = TRANWRD(pub_issue, 'N', 'No'); pub_issue = TRANWRD(pub_issue, 'R', 'Review');
	pub_issue = TRANWRD(pub_issue, 'U', 'Unsure'); pub_issue = TRANWRD(pub_issue, 'V', 'Verified');
	pub_issue = TRANWRD(pub_issue, 'X', 'No Fix'); pub_issue = TRANWRD(pub_issue, 'Y', 'Yes');
	
	open = TRANWRD(open, 'Y', 'Yes'); open = TRANWRD(open, 'N', 'No');
	
	links_flag = TRANWRD(links_flag, 'Y', 'Yes'); links_flag = TRANWRD(links_flag, 'N', 'No');
	
	/* If cell in collection is blank replace it with "None" */
	IF MISSING(ui_affected) THEN ui_affected = "None";
	IF MISSING(linktype_collection) THEN 
		DO;
		linktype_collection = "None";
		link_collection = "None" ;
		linktime_collection = "None" ;
		END;
/* Variable Formatting */
	/* Formatting unchanged variables from defects table (dates are already in proper format) */
		FORMAT defectid $CHAR8. reptid $CHAR40. mixedcase_title $CHAR100. product $CHAR8. component $CHAR20. priority $CHAR7. keywords $CHAR100. 
	    ui_affected $CHAR20. pub_issue $CHAR8. open $CHAR3. openloc $CHAR40. closeloc $CHAR100. links_flag $CHAR3.
	/* Formatting history variables (dates are already in proper format) */
	    location_collection $CHAR300. status_collection $CHAR300. track_collection $CHAR300. platform_collection $CHAR300. history_collection $CHAR300. 
	    completion_time 4. current_platform $CHAR3. current_track $CHAR10. current_status $CHAR20. current_location $CHAR20. 
	/* Formatting link table variables */
	    linktype_collection $CHAR300. linktime_collection $CHAR300. link_collection $CHAR300.
	/* Formatting TSNumber table variables */
		tsnumber_collection $CHAR300. current_tsnumber $CHAR20.
	/* Formatting calculated variables */
		num_defer 2. num_dupto 2. num_dupfrom 2. num_blocking 2. num_blockedby 2. relations 2. num_links 2. 
	    status_changes 2. location_changes 2. track_changes 2. virulence 3. age 4.;
	    
	    
	    
/* Define which variable to keep in the resulting data set */
	/* Unchanged variables from defects table*/
		KEEP defectid reptid mixedcase_title product component priority keywords ui_affected pub_issue open openloc closeloc links_flag
	/* Calculated variables	 */
	    completion_time num_defer num_dupto num_dupfrom num_blocking num_blockedby relations num_links status_changes location_changes track_changes virulence age
	/* history table variables */
		current_status current_location current_track current_platform creation_date creation_datetime lasthistory_datetime 
		lasthistory_date status_collection location_collection track_collection platform_collection history_collection      
	/* TSNumber table variables */
		tsnumber_collection current_tsnumber num_tsnumber 
	/* Link table variables */
	    link_collection linktype_collection linktime_collection;
	
	
/* Give labels to each variable */
	/* 	Unchanged variable labels from defects table */
	LABEL defectid = "DefectID" reptid = "Creator" mixedcase_title = "Title" product = "Product" component = "Component" 
		  priority = "Priority" creation_date = "Creation Date" keywords = "Keyword(s)" ui_affected = "UI Affected" 
		  pub_issue = "Pubs Issue" open = "Open Flag" openloc = "Open Location(s)" closeloc = "Closed Location(s)" 
		  links_flag = "Links Flag"  
	/* history table variables */
		  location_collection = "Location Collection" status_collection = "Status Collection" track_collection = "Track Collection" 
		  platform_collection = "Platform Collection" history_collection = "History Collection"  
		  current_platform = "Current Platform" current_track = "Track" current_status = "Current Status" current_location = "Last Location"
		  lasthistory_date = "Last Updated Date" lasthistory_datetime = "Last Updated Datetime" completion_time = "Completion Time"
	/* link table variables */
		  link_collection = "Link Collection" linktype_collection = "Link Type Collection" linktime_collection = "Link Time Collection" 
	/* TSNumber variables */
		  tsnumber_collection = "TSNumber Collection" current_tsnumber = "Current TSnumber" num_tsnumber = "# of TSNumber"
	/* calculated variables */
		  num_defer = "# of Defer" num_dupto = "# of Dup to" num_dupfrom = "# of Dup from" num_blocking = "# of Blocking"
		  num_blockedby = "# of Blocked by" relations = "# of Related to" num_links = "# of Links" num_keywords = "# of Keywords" status_changes = "# of Status Changes" 
		  location_changes = "# of Location Changes" track_changes = "# of Track Changes" virulence = "Virulence" age = "Age(Days)";
RUN;	


/* Creating a separate dataset for Keywords */
DATA keyword_arrays;
	SET full_data;
	LENGTH Keyword1-Keyword8 $20.;
	ARRAY Keyword(8) $;
		DO i = 1 TO dim(Keyword);
		Keyword[i]=SCAN(keywords,i,' ','M');
		END;
	KEEP Keyword1-Keyword8 defectid reptid creation_date current_track product component current_status current_location priority completion_time;
RUN;


/* Use SQL to merge the 8 separate keyword columns from helena_keyword_arrays into one long column */
/* We also want to keep important variables so we can filter the data later */
PROC SQL;
	CREATE TABLE keyword_column AS
		SELECT * FROM keyword_arrays(keep = defectid reptid keyword1 creation_date current_track product component current_status current_location priority completion_time) UNION ALL
		SELECT * FROM keyword_arrays(keep = defectid reptid keyword2 creation_date current_track product component current_status current_location priority completion_time) UNION ALL
		SELECT * FROM keyword_arrays(keep = defectid reptid keyword3 creation_date current_track product component current_status current_location priority completion_time) UNION ALL
		SELECT * FROM keyword_arrays(keep = defectid reptid keyword4 creation_date current_track product component current_status current_location priority completion_time) UNION ALL
		SELECT * FROM keyword_arrays(keep = defectid reptid keyword5 creation_date current_track product component current_status current_location priority completion_time) UNION ALL
		SELECT * FROM keyword_arrays(keep = defectid reptid keyword6 creation_date current_track product component current_status current_location priority completion_time) UNION ALL
		SELECT * FROM keyword_arrays(keep = defectid reptid keyword7 creation_date current_track product component current_status current_location priority completion_time) UNION ALL
		SELECT * FROM keyword_arrays(keep = defectid reptid keyword8 creation_date current_track product component current_status current_location priority completion_time);
QUIT;


/* Sort the combined tables by defectid, remove empty cells, and remove commas */
PROC SORT DATA=keyword_column(RENAME = (keyword1 = keyword)) OUT=keywords_data;
     BY defectid;
     WHERE keyword is NOT missing AND keyword ~= ',';
     FORMAT keyword $CHAR20.;
     LABEL defectid = "DefectID" creation_date = "Creation Date" completion_time = "Completion Time" product = "Product" 
     component = "Component" current_track = "Current Track" current_status = "Current Status" keyword = "Keyword" priority = "Priority" current_location = "Current Location"; 
RUN;

