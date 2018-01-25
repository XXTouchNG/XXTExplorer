#import <Foundation/Foundation.h>

@interface NSString (VersionValue)

- (NSComparisonResult)compareVersion:(nonnull NSString *)version;

@end


@implementation NSString (VersionValue)

static inline NSComparisonResult NSComparationInt(int a, int b) {
	if (a == b) return NSOrderedSame;
	return (a > b) ? (NSOrderedDescending) : (NSOrderedAscending);
}

- (NSComparisonResult)compareVersion:(nonnull NSString *)version {
	static NSCharacterSet *separatorSet = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" .-"];
	});
	int digit = 0, digit_v = 0;
	NSScanner *scanner = [NSScanner scannerWithString:self];
	NSScanner *scanner_v = [NSScanner scannerWithString:version];
	BOOL scan = [scanner scanInt:&digit];
	BOOL scan_v = [scanner_v scanInt:&digit_v];
	while (scan && scan_v) {
		if (digit != digit_v) {
			break;
		}
		digit = 0; digit_v = 0;
		[scanner scanCharactersFromSet:separatorSet intoString:nil];
		[scanner_v scanCharactersFromSet:separatorSet intoString:nil];
		scan = [scanner scanInt:&digit];
		scan_v = [scanner_v scanInt:&digit_v];
	}
	return NSComparationInt(digit, digit_v);
}

@end

int main(int argc, char *argv[]) {
	@autoreleasepool {
		assert([@"" compareVersion:@""] == NSOrderedSame);
		
		assert([@"1" compareVersion:@""] == NSOrderedDescending);
		assert([@"" compareVersion:@"1"] == NSOrderedAscending);
		assert([@"1" compareVersion:@"1"] == NSOrderedSame);
		
		assert([@"1.0" compareVersion:@"1"] == NSOrderedSame);
		assert([@"1" compareVersion:@"1.0"] == NSOrderedSame);
		assert([@"1." compareVersion:@"1"] == NSOrderedSame);
		assert([@"1" compareVersion:@"1."] == NSOrderedSame);
		assert([@"1." compareVersion:@"1.0"] == NSOrderedSame);
		assert([@"1.0" compareVersion:@"1."] == NSOrderedSame);
		assert([@"1.0" compareVersion:@"1.0"] == NSOrderedSame);
		assert([@"1.0.0" compareVersion:@"1.0.0"] == NSOrderedSame);
		
		assert([@"1.1" compareVersion:@"1.0"] == NSOrderedDescending);
		assert([@"1.0" compareVersion:@"1.1"] == NSOrderedAscending);
		
		assert([@"1.1" compareVersion:@"1.10"] == NSOrderedAscending);
		assert([@"1.2" compareVersion:@"1.11"] == NSOrderedAscending);
		assert([@"1.1" compareVersion:@"1.1.1"] == NSOrderedAscending);
		assert([@"1.2" compareVersion:@"1.1.1"] == NSOrderedDescending);
		
		assert([@"1.10.1" compareVersion:@"1.10"] == NSOrderedDescending);
		assert([@"1.2-4" compareVersion:@"1.2-3"] == NSOrderedDescending);
		
		assert([@"1.2-3" compareVersion:@"1.2.3"] == NSOrderedSame);
		assert([@"1.2-4" compareVersion:@"1.2.3.0"] == NSOrderedDescending);
		assert([@"1.2-4" compareVersion:@"1.2.3.10"] == NSOrderedDescending);
		assert([@"1.2-4" compareVersion:@"1.2.30.10"] == NSOrderedAscending);
		assert([@"1.2-3" compareVersion:@"1.2.4"] == NSOrderedAscending);
		
		assert([@"2.2" compareVersion:@"1.2"] == NSOrderedDescending);
		assert([@"2.2" compareVersion:@"10.2"] == NSOrderedAscending);
		
		assert([@"2..2" compareVersion:@"2.2"] == NSOrderedSame);
		assert([@"2.2.x.3" compareVersion:@"2.2"] == NSOrderedSame);
		assert([@"x" compareVersion:@""] == NSOrderedSame);
	}
}