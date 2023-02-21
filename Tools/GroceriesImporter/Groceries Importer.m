#import <Foundation/Foundation.h>

#import "NSCountedSet+Additions.h"
#import "NSString+Additions.h"
#import "NSString+SQL.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSDictionary* languageCodes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:1], @"en",
		[NSNumber numberWithInteger:2], @"de",
		nil];
	
	// Import the aisles
	NSURL* URL = [NSURL fileURLWithPath:@"/Users/sophia/aisles"];
	
	NSError* error = nil;
	NSXMLDocument* document = [[NSXMLDocument alloc] initWithContentsOfURL:URL options:NSXMLDocumentTidyXML error:&error];
	NSArray* rows = [document nodesForXPath:@"//ROW" error:&error];
	[document release];
	
	NSMutableDictionary* aisles = [NSMutableDictionary dictionary];
	
	for(NSXMLNode* row in rows) {
		NSString* aisleCode = [[[[row childAtIndex:0] childAtIndex:0] childAtIndex:0] stringValue];
		NSInteger aisleID = [[[[[row childAtIndex:1] childAtIndex:0] childAtIndex:0] XMLStringWithOptions:NSXMLNodeOptionsNone] integerValue];
		
		[aisles setObject:[NSNumber numberWithInteger:aisleID] forKey:aisleCode];
	}
	
	// Import the paths
	URL = [NSURL fileURLWithPath:@"/Users/sophia/path-aisle"];
	
	document = [[NSXMLDocument alloc] initWithContentsOfURL:URL options:NSXMLDocumentTidyXML error:&error];
	rows = [document nodesForXPath:@"//ROW" error:&error];
	[document release];
	
	NSMutableDictionary* paths = [NSMutableDictionary dictionary];
	
	for(NSXMLNode* row in rows) {
		NSString* aisleCode = [[[[row childAtIndex:1] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* path = [[[[row childAtIndex:0] childAtIndex:0] childAtIndex:0] stringValue];
		
//		NSLog(@"%@ = %@", aisleCode, path);
		
		if(path && aisleCode) {
			[paths setObject:aisleCode forKey:path];
		}
	}
	
	// Import the units
	URL = [NSURL fileURLWithPath:@"/Users/sophia/Einheiten"];
	
	document = [[NSXMLDocument alloc] initWithContentsOfURL:URL options:NSXMLDocumentTidyXML error:&error];
	rows = [document nodesForXPath:@"//ROW" error:&error];
	[document release];
	
	NSOutputStream* unitsFile = [NSOutputStream outputStreamToFileAtPath:@"/Users/sophia/standard_units.sql" append:NO];
	
	[unitsFile open];
	
	NSMutableDictionary* units = [NSMutableDictionary dictionary];
	
	for(NSXMLNode* row in rows) {
		NSString* abbr = [[[[row childAtIndex:0] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* nameDE = [[[[row childAtIndex:1] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* namePluralDE = [[[[row childAtIndex:2] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* shortNameDE = [[[[row childAtIndex:3] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* shortNamePluralDE = [[[[row childAtIndex:4] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* nameEN = [[[[row childAtIndex:5] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* namePluralEN = [[[[row childAtIndex:6] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* shortNameEN = [[[[row childAtIndex:7] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* shortNamePluralEN = [[[[row childAtIndex:8] childAtIndex:0] childAtIndex:0] stringValue];
		
		NSInteger unitID = [[[(id)row attributeForName:@"RECORDID"] stringValue] longLongValue] + 10000;
		
		abbr = [abbr lowercaseString];
		NSLog(@"%@", abbr);
		
		NSString* unitStatementString = [NSString stringWithFormat:@"INSERT INTO units (id, name_en, plural_name_en, short_name_en, plural_short_name_en, name_de, plural_name_de, short_name_de, plural_short_name_de) VALUES (%ld, %@, %@, %@, %@, %@, %@, %@, %@);\n",
			unitID,
			[nameEN stringByConvertingToSQLInsertString],
			[namePluralEN stringByConvertingToSQLInsertString],
			[shortNameEN stringByConvertingToSQLInsertString],
			[shortNamePluralEN stringByConvertingToSQLInsertString],
			[nameDE stringByConvertingToSQLInsertString],
			[namePluralDE stringByConvertingToSQLInsertString],
			[shortNameDE stringByConvertingToSQLInsertString],
			[shortNamePluralDE stringByConvertingToSQLInsertString],
			nil];
		NSData* deleteData = [unitStatementString dataUsingEncoding:NSUTF8StringEncoding];
		[unitsFile write:[deleteData bytes] maxLength:[deleteData length]];
			
		if(abbr) {
			[units setObject:[NSNumber numberWithInteger:unitID] forKey:abbr];
		}
	}
	
	URL = [NSURL fileURLWithPath:@"/Users/sophia/db"];
	
	document = [[NSXMLDocument alloc] initWithContentsOfURL:URL options:NSXMLDocumentTidyXML error:&error];
	rows = [document nodesForXPath:@"//ROW" error:&error];
	[document release];
	
	NSOutputStream* file = [NSOutputStream outputStreamToFileAtPath:@"/Users/sophia/standard_groceries.sql" append:NO];
	
	[file open];
	
	
	NSOutputStream* autocompleteDEFile = [NSOutputStream outputStreamToFileAtPath:@"/Users/sophia/autocomplete_de.sql" append:NO];
	[autocompleteDEFile open];
	
	NSOutputStream* autocompleteENFile = [NSOutputStream outputStreamToFileAtPath:@"/Users/sophia/autocomplete_en.sql" append:NO];
	[autocompleteENFile open];
	
	
	NSData* deleteData = [@"DELETE FROM groceries;\n" dataUsingEncoding:NSUTF8StringEncoding];
	[file write:[deleteData bytes] maxLength:[deleteData length]];
	
	NSInteger numberOfTooLargeItems = 0;
	NSInteger numberOfItemsAdded = 0;
	NSInteger numberOfItemsWithInvalidSuffix = 0;
	
	NSArray* invalidPrefixes = [NSArray arrayWithObjects:
		@"Annie",
		@"Whiskas",
		@"Sunkist",
		@"Newman's Own Dressing,",
		@"Kraft",
		@"Coffee-Mate",
		@"Coffee Mate",
		@"Crowley",
		@"Fleischmann",
		@"So Delicious",
		@"Powerade",
		@"Propel",
		@"Red Bull",
		@"Rockstar",
		@"Salada",
		@"Saranac",
		@"Smirnoff",
		@"SoBe",
		@"Tropicana Twister",
		@"V8",
		@"Little Debbie",
		@"Hostess",
		@"Pepperidge",
		@"Nature's Own",
		@"Miss Meringue Classiques",
		@"Monk's",
		@"Vermont",
		@"Quaker",
		@"Rice Krispies",
		@"Smucker",
		@"Yogos",
		@"Pepperidge",
		@"Smart Balance",
		@"Snyder",
		@"Utz",
		@"Wheat Thins",
		@"Barilla Enriched",
		@"3 ",
		@"5 ",
		@"100",
		@"Contadina",
		@"Extra",
		@"Green & Black",
		@"Ghirardelli",
		@"Kitchen Basics",
		@"LifeSavers",
		@"Orbit",
		@"Perugina",
		@"Progresso",
		@"Russell",
		@"Superior",
		@"Trident",
		@"Pillsbury",
		@"Giovanni"
		@"FoodShouldTaste",
		@"Cascadian",
		@"Castor",
		@"Arrowhead",
		// @"Kellogg's Pop-Tarts",
		nil];
	
	for(NSXMLNode* row in rows) {
		// NSLog(@"%@", row);
		
		 NSAutoreleasePool * pool2 = [[NSAutoreleasePool alloc] init];
		
		NSUInteger groceryID = [[[[[row childAtIndex:0] childAtIndex:0] childAtIndex:0] stringValue] longLongValue];
	
		NSString* name = [[[[row childAtIndex:1] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* note = [[[[row childAtIndex:2] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* path = [[[[row childAtIndex:3] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* availableUnits = [[[[row childAtIndex:4] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* generic = [[[[row childAtIndex:5] childAtIndex:0] childAtIndex:0] stringValue];
		NSString* languageCode = [[[[row childAtIndex:6] childAtIndex:0] childAtIndex:0] stringValue];
		
		name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		if([name hasSuffix:@"&"]) {
			NSLog(@"%@ has invalid suffix", name);
			++numberOfItemsWithInvalidSuffix;
			continue;
		}
		
		if([name hasSuffix:@"-"]) {
			NSLog(@"%@ has invalid suffix", name);
			++numberOfItemsWithInvalidSuffix;
			continue;
		}
		
		BOOL needsToContinue = NO;
		
		for(NSString* invalidPrefix in invalidPrefixes) {
			if([name hasPrefix:invalidPrefix]) {
				NSLog(@"%@ has invalid prefix", name);
				++numberOfItemsWithInvalidSuffix;
				needsToContinue = YES;
				break;
			}
		}
		
		if(needsToContinue) {
			continue;
		}
		
		NSNumber* language = [languageCodes objectForKey:languageCode];
		
		NSString* aisleCode = [paths objectForKey:path];
		NSNumber* aisleID = [aisles objectForKey:aisleCode];
		
		if(!aisleID) {
			NSLog(@"Invalid aisle for %@, %@", name, path);
			continue;
		}

/*		
		if([aisleID integerValue] == 26 && ![generic boolValue]) {
			// NSLog(@"Ignore makeup item %@", name, path);
			++numberOfItemsWithInvalidSuffix;
			continue;
		}
*/
		
		if([aisleID integerValue] == 4 && ![generic boolValue] && [language integerValue] == 1) {
			NSLog(@"Ignore bread item %@", name, path);
			++numberOfItemsWithInvalidSuffix;
			continue;
		}
		
		if([aisleID integerValue] == 13 && ![generic boolValue] && [language integerValue] == 1) {
			NSLog(@"Ignore baby item %@", name, path);
			++numberOfItemsWithInvalidSuffix;
			continue;
		}
		
		if([aisleID integerValue] == 17 && ![generic boolValue] && [language integerValue] == 1) {
			NSLog(@"Ignore household item %@", name, path);
			++numberOfItemsWithInvalidSuffix;
			continue;
		}
		
		if([aisleID integerValue] == 18 && ![generic boolValue] && [language integerValue] == 1) {
			NSLog(@"Ignore office item %@", name, path);
			++numberOfItemsWithInvalidSuffix;
			continue;
		}
		
		if([aisleID integerValue] == 21 && ![generic boolValue] && [language integerValue] == 1) {
			NSLog(@"Ignore fruit item %@", name, path);
			++numberOfItemsWithInvalidSuffix;
			continue;
		}
		
		if([aisleID integerValue] == 22 && ![generic boolValue] && [language integerValue] == 1) {
			NSLog(@"Ignore meat item %@", name, path);
			++numberOfItemsWithInvalidSuffix;
			continue;
		}

		
//		if(title.length > 30 || note.length > 38) {
//			NSLog(@"Skipping %@ - %@", title, note);
//			continue;
//		}

		NSMutableArray* preparedSearchNames = [NSMutableArray array];
		
		NSArray* nameSearchNames = [name searchExpressions];
		NSArray* noteSearchNames = [note searchExpressions];
		
		id searchNames = nameSearchNames;
		searchNames = [searchNames arrayByAddingObjectsFromArray:noteSearchNames];
		
		searchNames = [NSSet setWithArray:searchNames];

		for(NSString* aSearchName in searchNames) {
			aSearchName = [aSearchName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

			if(aSearchName.length > 1) {
				// aSearchName = [aSearchName stringByTrimmingCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]];
				// aSearchName = [aSearchName stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
				
				if(aSearchName.length > 0) {
					[preparedSearchNames addObject:aSearchName];
				}
			}
		}
		
		if(nameSearchNames.count > 4 || noteSearchNames.count > 5 || (nameSearchNames.count > 3 && noteSearchNames.count > 3)) {
			// NSLog(@"%@ is too large", name);
			++numberOfTooLargeItems;
			continue;
		}
		
		if(preparedSearchNames.count > 0) {
			// NSLog(@"%@", preparedSearchNames);
			
			for(NSString* aSearchName in preparedSearchNames) {
				NSString* searchNameStatement = [NSString stringWithFormat:@"INSERT INTO __%@_autocomplete_%@_%@ (name, grocery_id) VALUES (%@, %lu);\n",
					[generic boolValue] ? @"grocery" : @"brand",
					languageCode,
					[aSearchName searchIndexString],
					[aSearchName stringByConvertingToSQLInsertString],
			//		preparedSearchNames.count,
			//		generic,
			//		language,
					groceryID];
				
				NSOutputStream* autocompleteFile = [languageCode isEqualToString:@"de"] ? autocompleteDEFile : autocompleteENFile;
				
				NSData* searchNameStatementData = [searchNameStatement dataUsingEncoding:NSUTF8StringEncoding];
				[autocompleteFile write:[searchNameStatementData bytes] maxLength:[searchNameStatementData length]];
			}
		}
		
		// Now determine the default unit
		availableUnits = [availableUnits lowercaseString];

		NSArray* availableUnits2 = [availableUnits componentsSeparatedByString:@","];
		NSCountedSet* countedUnits = [[[NSCountedSet alloc] initWithArray:availableUnits2] autorelease];
		NSString* unitWithHighestCount = [countedUnits objectWithHighestCount];
		
		if(!unitWithHighestCount) {
			unitWithHighestCount = availableUnits2.count > 0 ? [availableUnits2 objectAtIndex:0] : nil;
		}
		
		NSNumber* unitID = [units objectForKey:unitWithHighestCount];
		
		if(!unitID) {
			unitID = [units objectForKey:@"stk"];
		}
		
		// ...
		NSString* statement = [NSString stringWithFormat:@"INSERT INTO groceries (name, note, generic, aisle_id, unit_id, language, id) VALUES (%@, %@, %i, %@, %@, %@, %lu);\n",
			[name stringByConvertingToSQLInsertString],
			[note stringByConvertingToSQLInsertString],
			[generic boolValue] ? 1 : 0,
			aisleID,
			unitID ? unitID : @"(null)",
			language,
			groceryID];
		
		// NSLog(statement);
		
		NSData* data = [statement dataUsingEncoding:NSUTF8StringEncoding];
		NSInteger bytesWritten = [file write:[data bytes] maxLength:[data length]];
		
		if(!bytesWritten) {
		}
		
		++numberOfItemsAdded;
		
		[pool2 release];
	}
	
	NSLog(@"%i items where too large to add.", numberOfTooLargeItems);
	NSLog(@"%i items where added to the library.", numberOfItemsAdded);
	NSLog(@"%i items had a invalid suffix.", numberOfItemsWithInvalidSuffix);
	
	[file close];
	
    [pool drain];

    return 0;
}
