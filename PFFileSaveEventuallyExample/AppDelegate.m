//
//  AppDelegate.m
//  PFFileSaveEventuallyExample
//
//  Created by Thibaud David on 10/09/2015.
//  Copyright (c) 2015 Thibaud David. All rights reserved.
//

#import "AppDelegate.h"
#import "Parse.h"
#import "PFFileEventuallySaver.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString *parseClientID = nil;
    NSString *parseClientKey = nil;
    
    
    [Parse enableLocalDatastore];
    if(parseClientID && parseClientKey)
    {
        [Parse setApplicationId:parseClientID clientKey:parseClientKey];
        
        /*
            On PFFileEventuallySave init, a tmp directory will be created to store data of unsaved PFfiles");
         */
        [PFFileEventuallySaver getInstance];
        
        if(![[PFFileEventuallySaver getInstance] hasPendingFiles])
        { // Avoid adding several time this sample to queue
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
            {
                               [self startExample];
            });
        }
    }
    else
    {
        NSLog(@"To test this example, you must setup a valid parseClientID and parseClientKey in AppDelegate.h");
    }
    

    return YES;
}

-(void)startExample
{
    /*
     This example uses an UIImage, but this works with any file writable as NSData
     We begin by writing this image in our tmp directory with an uuid as name.
     */
    UIImage *nyancat = [UIImage imageNamed:@"nyancat.jpg"];
    NSData *imageData = UIImageJPEGRepresentation(nyancat, 0.5);
    
    NSString *filename = [[NSUUID UUID] UUIDString];
    NSURL *fileUrl = [PFFileEventuallySaver fileURLInTmpWithName:filename];
    
    [imageData writeToURL:fileUrl atomically:YES];
    
    
    /*
     We create a PFObject (you can pass an array to below function if you need your file to be saved on several objects). If upload works on first time, do what you want with your file, like linking it on your PFobject.
     
     If saving fails, it'll be retried as soon as network is available, on this session or nexts launches of app.
     In that case, the pointer at key kPFFILE_MANAGER_OBJECT_FILE_KEY of your PFFObject will be set with the PFFile, then saved eventually within PFFileEventuallySaver
     */
    PFObject *object = [PFObject objectWithClassName:kPFFILE_CONTAINER_OBJECT_CLASSNAME];
    
    [[PFFileEventuallySaver getInstance] trySaveobjectAtURL:fileUrl associatedObjects:@[object] withBlock:^(PFFile *file, NSError *error) {
        if(!error)
        {
            NSLog(@"[First try, network is fine] File saved, saving PFObject");
            
            object[kPFFILE_MANAGER_OBJECT_FILE_KEY] = file;
            [object saveEventually];
            
            NSLog(@"Try again disabling your network connection");
        }
        else
        {
            NSLog(@"No network, connect back your wifi, or relaunch app. Your file will be sent");
        }
    } progressBlock:^(int percentDone) {
        NSLog(@"[First try, network is fine] Sending file %d/100%%", percentDone);
    }];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
