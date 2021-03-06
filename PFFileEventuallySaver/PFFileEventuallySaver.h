//
//  PFFileEventuallySaver.h
//  PFFileSaveEventuallyExample
//
//  Created by Thibaud David on 10/09/2015.
//  Copyright (c) 2015 Thibaud David. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PFFile;

#define kPFFILE_MANAGER_OBJECT_FILE_KEY @"file"
#define kPFFILE_MANAGER_TMP_DIRECTORY @"tmpPFFiles"
#define kPFFILE_MANAGER_PENDING_FILES @"PFPendingFiles"
#define kPFFILE_CONTAINER_OBJECT_CLASSNAME @"MyObjectClass"

@interface PFFileEventuallySaver : NSObject

+(instancetype)getInstance;

-(void)trySaveobjectAtURL:(NSURL *)URL associatedObjects:(NSArray *)objects withBlock:(void(^)(PFFile *file, NSError *error))block progressBlock:(void(^)(int percentDone))progressBlock;
+(NSURL *)fileURLInTmpWithName:(NSString *)filename;
-(BOOL)hasPendingFiles;

@end
