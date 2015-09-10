//
//  PFFileEventuallySaver.m
//  PFFileSaveEventuallyExample
//
//  Created by Thibaud David on 10/09/2015.
//  Copyright (c) 2015 Thibaud David. All rights reserved.
//

#import "PFFileEventuallySaver.h"
#import "Reachability.h"
#import "Parse.h"

@implementation PFFileEventuallySaver
{
    NSMutableArray *pendingUploads;
}

+(instancetype)getInstance
{
    static PFFileEventuallySaver *INSTANCE;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        INSTANCE = [[self alloc] init];
    });
    return INSTANCE;
}

-(instancetype)init
{
    self = [super init];
    
    if(self)
    {
        Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
        [reach startNotifier];
        
        [self createTmpFolderIfNotExisting];
        
        NSArray *previousPending = [[NSArray alloc] initWithContentsOfFile:[PFFileEventuallySaver pendingFile]];
        pendingUploads = previousPending ? [previousPending mutableCopy] : [NSMutableArray array];
        NSLog(@"Pending uploads :\n%@", pendingUploads);
        
        [self handleNetworkReachable];
    }
    return self;
}
-(BOOL)hasPendingFiles
{
    return pendingUploads.count > 0;
}

-(void)handleNetworkReachable
{
    [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
     {
         Reachability * reach = [note object];
         
         if([reach isReachable])
         {
             if(pendingUploads.count > 0)
             {
                 NSLog(@"[PFFileManager] Handling %lu pending uploads", (unsigned long)pendingUploads.count);
                 for(NSString *objectName in [pendingUploads copy])
                 {
                     [self localobjectsForURL:objectName withBlock:^(NSArray *objects, NSError *error)
                      {
                          if(!error)
                          {
                              NSURL *fileURL = [PFFileEventuallySaver fileURLInTmpWithName:objectName];
                              [self trySaveobjectAtURL:fileURL associatedObjects:objects withBlock:^(PFFile *file, NSError *error)
                               {
                                   if(!error)
                                   {
                                       for(PFObject *object in objects)
                                       {
                                           object[kPFFILE_MANAGER_OBJECT_FILE_KEY] = file;
                                           [object saveEventually];
                                       }
                                   }
                                   else
                                   {
                                       NSLog(@"[PFFileManager] Still an error, will try again on next reachability %@", error);
                                   }
                               } progressBlock:^(int percentDone) {
                                   
                               }];
                          }
                          else
                          {
                              NSLog(@"[PFFileManager] Couldn't retrieve objects for filename %@", objectName);
                          }
                      }];
                 }
             }
         }
     }];
}

-(void)localobjectsForURL:(NSString *)URL withBlock:(void(^)(NSArray *objects, NSError *error))block
{
    PFQuery *query = [PFQuery queryWithClassName:kPFFILE_CONTAINER_OBJECT_CLASSNAME];
    [query fromPinWithName:URL];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if(!error)
             block(objects, nil);
         else
             block(nil, error);
     }];
}

-(void)createTmpFolderIfNotExisting
{
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", kPFFILE_MANAGER_TMP_DIRECTORY]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
        
        if(error)
            NSLog(@"Error creating tmp folder %@", error);
    }
    else
        NSLog(@"Tmp folder already exists");
}

+(NSString *)pendingFile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    return [path stringByAppendingPathComponent:kPFFILE_MANAGER_PENDING_FILES];
}

+(NSURL *)fileURLInTmpWithName:(NSString *)filename
{
    NSURL *applicationDocumentsDirectoryy =[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                                   inDomains:NSUserDomainMask] lastObject];
    return [[applicationDocumentsDirectoryy URLByAppendingPathComponent:kPFFILE_MANAGER_TMP_DIRECTORY] URLByAppendingPathComponent:filename];
}

+(void)deleteFileAtURL:(NSURL *)url
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    if(error)
        NSLog(@"Error deleting file with name %@ --> %@", [url lastPathComponent], error);
}

-(void)trySaveobjectAtURL:(NSURL *)URL associatedObjects:(NSArray *)objects withBlock:(void(^)(PFFile *file, NSError *error))block progressBlock:(void(^)(int percentDone))progressBlock
{
    PFFile *file = [PFFile fileWithData:[NSData dataWithContentsOfURL:URL]];
    
    [self addUrlToQueue:URL withobjects:objects];
    
    [file saveInBackgroundWithBlock:^(BOOL success, NSError *error)
     {
         if(!error)
         {
             [PFFileEventuallySaver deleteFileAtURL:URL];
             [self removeURLFromQueue:URL withobjects:objects];
             block(file, nil);
         }
         else{
             block(nil, error);
         }
     }
     progressBlock:progressBlock];
}
-(void)persistPendingUploads
{
    [pendingUploads writeToFile:[PFFileEventuallySaver pendingFile] atomically:YES];
}

-(void)addUrlToQueue:(NSURL *)URL withobjects:(NSArray *)objects
{
    NSLog(@"[PFFileManager] Adding file with name %@ to queue with %lu associated objects", [URL lastPathComponent], (unsigned long)objects.count);
    [pendingUploads addObject:[URL lastPathComponent]];
    [self persistPendingUploads];
    [PFObject pinAllInBackground:objects withName:[URL lastPathComponent]];
}
-(void)removeURLFromQueue:(NSURL *)URL withobjects:(NSArray *)objects
{
    NSLog(@"[PFFileManager] Removing file with name %@ to queue with %lu associated objects", [URL lastPathComponent], (unsigned long)objects.count);
    [pendingUploads removeObject:[URL lastPathComponent]];
    [self persistPendingUploads];
    [PFObject unpinAllInBackground:objects withName:[URL lastPathComponent]];
}

@end
