//
//  ZZZipTests.h
//  zipzap
//
//  Created by Glen Low on 18/10/12.
//
//

#import <XCTest/XCTest.h>

@interface ZZZipTests : XCTestCase

- (void)setUp;
- (void)tearDown;

- (void)testCreatingFileZipWithNoEntries;
- (void)testCreatingFileZipEntriesWithDirectory;

- (void)testCreatingFileZipEntriesWithCompressedData;
- (void)testCreatingFileZipEntriesWithUncompressedData;
- (void)testCreatingFileZipEntriesWithCompressedStreamInSmallChunks;
- (void)testCreatingFileZipEntriesWithCompressedStreamInLargeChunks;
- (void)testCreatingFileZipEntriesWithUncompressedStreamInSmallChunks;
- (void)testCreatingFileZipEntriesWithUncompressedStreamInLargeChunks;
- (void)testCreatingFileZipEntriesWithCompressedImage;
- (void)testCreatingFileZipEntriesWithUncompressedImage;

- (void)testCreatingFileZipEntriesWithCompressedBadData;
- (void)testCreatingFileZipEntriesWithUncompressedBadData;
- (void)testCreatingFileZipEntriesWithCompressedBadStreamWriteNone;
- (void)testCreatingFileZipEntriesWithUncompressedBadStreamWriteNone;
- (void)testCreatingFileZipEntriesWithCompressedBadStreamWriteSome;
- (void)testCreatingFileZipEntriesWithUncompressedBadStreamWriteSome;
- (void)testCreatingFileZipEntriesWithCompressedBadDataConsumerWriteNone;
- (void)testCreatingFileZipEntriesWithUncompressedBadDataConsumerWriteNone;

- (void)testInsertingFileZipEntryAtFront;
- (void)testInsertingFileZipEntryAtBack;
- (void)testInsertingFileZipEntryAtMiddle;
- (void)testReplacingFileZipEntryAtFront;
- (void)testReplacingFileZipEntryAtBack;
- (void)testReplacingFileZipEntryAtMiddle;
- (void)testRemovingFileZipEntryAtFront;
- (void)testRemovingFileZipEntryAtBack;
- (void)testRemovingFileZipEntryAtMiddle;

- (void)testInsertingFileZipEntryWithCompressedBadData;
- (void)testInsertingFileZipEntryWithUncompressedBadData;
- (void)testInsertingFileZipEntryWithCompressedBadStreamWriteNone;
- (void)testInsertingFileZipEntryWithUncompressedBadStreamWriteNone;
- (void)testInsertingFileZipEntryWithCompressedBadStreamWriteSome;
- (void)testInsertingFileZipEntryWithUncompressedBadStreamWriteSome;
- (void)testInsertingFileZipEntryWithCompressedBadDataConsumerWriteNone;
- (void)testInsertingFileZipEntryWithUncompressedBadDataConsumerWriteNone;

- (void)testCreatingDataZipWithNoEntries;
- (void)testCreatingDataZipEntriesWithDirectory;

- (void)testCreatingDataZipEntriesWithCompressedData;
- (void)testCreatingDataZipEntriesWithUncompressedData;
- (void)testCreatingDataZipEntriesWithCompressedStreamInSmallChunks;
- (void)testCreatingDataZipEntriesWithCompressedStreamInLargeChunks;
- (void)testCreatingDataZipEntriesWithUncompressedStreamInSmallChunks;
- (void)testCreatingDataZipEntriesWithUncompressedStreamInLargeChunks;
- (void)testCreatingDataZipEntriesWithCompressedImage;
- (void)testCreatingDataZipEntriesWithUncompressedImage;

- (void)testCreatingDataZipEntriesWithCompressedBadData;
- (void)testCreatingDataZipEntriesWithUncompressedBadData;
- (void)testCreatingDataZipEntriesWithCompressedBadStreamWriteNone;
- (void)testCreatingDataZipEntriesWithUncompressedBadStreamWriteNone;
- (void)testCreatingDataZipEntriesWithCompressedBadStreamWriteSome;
- (void)testCreatingDataZipEntriesWithUncompressedBadStreamWriteSome;
- (void)testCreatingDataZipEntriesWithCompressedBadDataConsumerWriteNone;
- (void)testCreatingDataZipEntriesWithUncompressedBadDataConsumerWriteNone;

- (void)testInsertingDataZipEntryAtFront;
- (void)testInsertingDataZipEntryAtBack;
- (void)testInsertingDataZipEntryAtMiddle;
- (void)testReplacingDataZipEntryAtFront;
- (void)testReplacingDataZipEntryAtBack;
- (void)testReplacingDataZipEntryAtMiddle;
- (void)testRemovingDataZipEntryAtFront;
- (void)testRemovingDataZipEntryAtBack;
- (void)testRemovingDataZipEntryAtMiddle;

- (void)testInsertingDataZipEntryWithCompressedBadData;
- (void)testInsertingDataZipEntryWithUncompressedBadData;
- (void)testInsertingDataZipEntryWithCompressedBadStreamWriteNone;
- (void)testInsertingDataZipEntryWithUncompressedBadStreamWriteNone;
- (void)testInsertingDataZipEntryWithCompressedBadStreamWriteSome;
- (void)testInsertingDataZipEntryWithUncompressedBadStreamWriteSome;
- (void)testInsertingDataZipEntryWithCompressedBadDataConsumerWriteNone;
- (void)testInsertingDataZipEntryWithUncompressedBadDataConsumerWriteNone;

@end
