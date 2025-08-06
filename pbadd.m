#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

static NSString * const kProgramVersion = @"1.0.0";

static NSString * const kFileURLType = @"public.file-url";
static NSString * const kFileNameType = @"public.file-name";

static void printUsage(const char *name) {
    printf("Usage: %s <file1> [file2] [file3] ...\n", name);
    printf("Add files to the clipboard from CLI as if they would be copied with Finder\n");
    printf("\nOptions:\n");
    printf("  -h, --help     Show this help message\n");
    printf("  -v, --version  Show version information\n");
}

static void printVersion(const char *name) {
    printf("%s version %s\n", name, [kProgramVersion UTF8String]);
}

static NSPasteboardItem *createPasteboardItem(NSURL *fileURL) {
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];

    NSString *fileURLString = [fileURL absoluteString];
    NSString *fileName = [fileURL lastPathComponent];

    BOOL success = YES;
    success &= [item setString:fileURLString forType:kFileURLType];
    success &= [item setString:fileName forType:kFileNameType];

    if (!success) {
        fprintf(stderr, "Warning: Failed to set pasteboard data for %s\n", [fileURLString UTF8String]);
    }

    return item;
}

// Verifies that the URLs are completely added to the pasteboard
static BOOL verifyPasteboardContents(NSPasteboard *pasteboard, NSArray<NSURL *> *expectedURLs) {
    NSArray *readBack = [pasteboard readObjectsForClasses:@[[NSPasteboardItem class]] options:nil];

    if ([readBack count] != [expectedURLs count]) {
        return NO;
    }

    for (NSUInteger i = 0; i < [readBack count]; i++) {
        NSPasteboardItem *item = readBack[i];
        NSString *fileURLString = [item stringForType:kFileURLType];
        NSString *fileName = [item stringForType:kFileNameType];

        if (!fileURLString || !fileName) {
            return NO;
        }
    }

    return YES;
}

static BOOL addFilesToClipboard(NSArray<NSString *> *filePaths) {
    NSMutableArray<NSURL *> *fileURLs = [NSMutableArray array];

    // Convert paths to URLs
    for (NSString *path in filePaths) {
        NSURL *fileURL = [NSURL fileURLWithPath:path];

        [fileURLs addObject:fileURL];
    }

    // Add files to the clipboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];

    NSMutableArray<NSPasteboardItem *> *items = [NSMutableArray array];
    for (NSURL *fileURL in fileURLs) {
        [items addObject:createPasteboardItem(fileURL)];
    }

    BOOL success = [pasteboard writeObjects:items];
    if (!success) {
        return NO;
    }

    // Verify that the items are processed by the pastboard service.
    //
    // The verification is required because of how macOS handles pasteboard operations.
    // The items we post to the pastboard with writeObjects are precessed asynchronosly.
    // If the program exits before the pasteboard service has finished processing the write operation,
    // the data never actually makes it to the clipboard.

    for (NSInteger attempt = 0; attempt < 10; attempt++) {
        if (verifyPasteboardContents(pasteboard, fileURLs)) {
            return YES;
        }

        // Exponential backoff: 10ms, 20ms, 40ms, etc.
        usleep(10000 * (1 << attempt));
    }

    fprintf(stderr, "Warning: Pasteboard write may be incomplete\n");

    return NO;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            printUsage(argv[0]);
            return EXIT_FAILURE;
        }

        // Handle help flags
        if (argc == 2 && (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)) {
            printUsage(argv[0]);
            return EXIT_SUCCESS;
        }

        // Handle version flags
        if (argc == 2 && (strcmp(argv[1], "-v") == 0 || strcmp(argv[1], "--version") == 0)) {
            printVersion(argv[0]);
            return EXIT_SUCCESS;
        }

        NSFileManager *fileManager = [NSFileManager defaultManager];

        // Read paths from the arguments
        NSMutableArray<NSString *> *filePaths = [NSMutableArray array];
        for (int i = 1; i < argc; i++) {
            const char *arg = argv[i];

            // Check for unsupported options (arguments starting with - or --)
            if (arg[0] == '-') {
                fprintf(stderr, "Error: Unsupported option '%s'\n", arg);
                printUsage(argv[0]);
                return EXIT_FAILURE;
            }

            NSString *path = [NSString stringWithUTF8String:arg];
            NSString *expandedPath = [path stringByExpandingTildeInPath];
            if (![fileManager fileExistsAtPath:expandedPath]) {
                fprintf(stderr, "Error: File does not exist: %s\n", [expandedPath UTF8String]);
                return EXIT_FAILURE;
            }

            [filePaths addObject:expandedPath];
        }

        if (!addFilesToClipboard(filePaths)) {
            fprintf(stderr, "Failed to copy files to clipboard\n");
            return EXIT_FAILURE;
        }
    }

    return EXIT_SUCCESS;
}
