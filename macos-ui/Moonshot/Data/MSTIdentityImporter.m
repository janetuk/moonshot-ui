//
//  MSTIdentityImporter.m
//  Moonshot
//
//  Created by Ivan on 1/16/18.
//

#import "MSTIdentityImporter.h"
#import "TrustAnchor.h"
#import "SelectionRules.h"
#import "NSString+GUID.h"

@interface MSTIdentityImporter ()

@property (nonatomic, strong) NSMutableDictionary *identityDict;
@property (nonatomic, strong) NSMutableDictionary *ruleDict;
@property (nonatomic, strong) NSMutableDictionary *trustAnchorDict;
@property (nonatomic, strong) NSMutableArray *parsedIdentities;

@property (nonatomic, strong) NSMutableArray *xmlIdentitiesArray;
@property (nonatomic, strong) NSMutableArray *xmlServicesArray;
@property (nonatomic, strong) NSMutableArray *xmlSelectionRulesArray;
@property (nonatomic, strong) NSMutableString *xmlString;

@property (nonatomic, strong) NSError *parsingError;

@end

@implementation MSTIdentityImporter
- (void)importIdentitiesFromFile:(NSURL *)fileUrl withBlock:(void (^)(NSArray <Identity *> *items))block {
	NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithContentsOfURL:fileUrl];
	[xmlparser setDelegate:self];
	[xmlparser parse];

	[self convertDictsFromXMLArrayToIdentityObjects];
	if (block) {
		block(self.parsingError == nil? self.parsedIdentities : nil);
	}
}

#pragma mark - Convert Objects From XMLArray To Identity Objects

- (void)convertDictsFromXMLArrayToIdentityObjects {
	self.parsedIdentities = [[NSMutableArray alloc] init];
	
	for (NSObject *xmlObject in self.xmlIdentitiesArray) {
		Identity *identityObject = [[Identity alloc] init];
		TrustAnchor *trustAnchorObject = nil;
		NSMutableArray *selectionRulesArray = [[NSMutableArray alloc] init];
		if ([xmlObject valueForKey:@"selection-rules"] != nil) {
			NSArray *selectionArray = [xmlObject valueForKey:@"selection-rules"];
			for (id obj in selectionArray) {
				SelectionRules *rulesObject = [SelectionRules new];
                rulesObject.alwaysConfirm = [obj valueForKey:@"always-confirm"] ?: @"";
				rulesObject.pattern = [obj valueForKey:@"pattern"] ?: @"";
				[selectionRulesArray addObject:rulesObject];
			}
		}
		if ([xmlObject valueForKey:@"trust-anchor"] != nil) {
			NSDictionary *trustDict = [xmlObject valueForKey:@"trust-anchor"];
			trustAnchorObject = [[TrustAnchor alloc] init];
			trustAnchorObject.serverCertificate = [trustDict valueForKey:@"server-cert"] ?: @"";
			trustAnchorObject.caCertificate = [trustDict valueForKey:@"ca-cert"] ?: @"";
			trustAnchorObject.subject = [trustDict valueForKey:@"subject"] ?: @"";
			trustAnchorObject.subjectAlt = [trustDict valueForKey:@"subject-alt"] ?: @"";
		}
		identityObject.identityId = [NSString getUUID];
		identityObject.displayName = [xmlObject valueForKey:@"display-name"] ?: @"";
		identityObject.username = [xmlObject valueForKey:@"user"] ?: @"";
		identityObject.password = [xmlObject valueForKey:@"password"] ?: @"";
		identityObject.trustAnchor = trustAnchorObject;
		identityObject.realm = [xmlObject valueForKey:@"realm"] ?: @"";
		NSString *has2fa = [xmlObject valueForKey:@"has2fa"] ?: @"";
		identityObject.has2fa = ([has2fa isEqualToString:@"yes"] || [has2fa isEqualToString:@"true"]);
		identityObject.secondFactor = @"";
		identityObject.selectionRules = selectionRulesArray ?: [NSMutableArray arrayWithCapacity:0];
		identityObject.servicesArray = [xmlObject valueForKey:@"services"] ?: [NSMutableArray arrayWithCapacity:0];
		identityObject.passwordRemembered = identityObject.password.length > 0;
		identityObject.dateAdded = [NSDate date];
		[self.parsedIdentities addObject:identityObject];
	}
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if([elementName isEqualToString:@"identities"])
		self.xmlIdentitiesArray = [[NSMutableArray alloc] init];
	if([elementName isEqualToString:@"identity"])
		self.identityDict = [[NSMutableDictionary alloc] init];
	if ([elementName isEqualToString:@"services"]) {
		self.xmlServicesArray = [[NSMutableArray alloc] init];
	}
	if ([elementName isEqualToString:@"trust-anchor"]) {
		self.trustAnchorDict = [[NSMutableDictionary alloc] init];
	}
	if([elementName isEqualToString:@"rule"]) {
		self.ruleDict = [[NSMutableDictionary alloc] init];
	}
	if ([elementName isEqualToString:@"selection-rules"]) {
		self.xmlSelectionRulesArray = [[NSMutableArray alloc] init];
	}

}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if(!self.xmlString) {
		self.xmlString = [[NSMutableString alloc] initWithString:string];
	} else {
		[self.xmlString appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
		if ([elementName isEqualToString:@"service"]) {
			[self.xmlServicesArray addObject:[self.xmlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		}else if ([elementName isEqualToString:@"pattern"] || [elementName isEqualToString:@"always-confirm"]) {
			[self.ruleDict setObject:[self.xmlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:elementName];
		}else if ([elementName isEqualToString:@"rule"]) {
			[self.xmlSelectionRulesArray addObject:self.ruleDict];
		}else if ([elementName isEqualToString:@"server-cert"] || [elementName isEqualToString:@"ca-cert"] || [elementName isEqualToString:@"subject"] || [elementName isEqualToString:@"subject-alt"]) {
			[self.trustAnchorDict setObject:[self.xmlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:elementName];
		} else {
			[self.identityDict setObject:[self.xmlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:elementName];
		}
		if (self.xmlSelectionRulesArray) {
			[self.identityDict setObject:self.xmlSelectionRulesArray forKey:@"selection-rules"];
		}
		if (self.trustAnchorDict) {
			[self.identityDict setObject:self.trustAnchorDict forKey:@"trust-anchor"];
		}
		if (self.xmlServicesArray) {
			[self.identityDict setObject:self.xmlServicesArray forKey:@"services"];
		}
		if ([elementName isEqualToString:@"identity"]) {
			[self.xmlIdentitiesArray addObject:self.identityDict];
		}
		self.xmlString = [[NSMutableString alloc] init];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	self.parsingError = parseError;
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError {
	self.parsingError = validationError;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	self.parsingError = parser.parserError;
}




@end
