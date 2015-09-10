### PFFileEventuallySaver

This is a sample class to save a PFFile eventually.

As you might know, that feature isn't available within ParseSDK.

That's only a working PoC with limitations such as only working for a single Parse class to associate saved PFFile on.

It requires Reachability `pod 'Reachability', '~> 3.2'`

How to use it ? Well, I guess the sample projects describes it well, but here is a piece of code to understand how it works :

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
    
    
This  could be greatly improved, but I thought you guys might found that useful, as I would've wanted to find a similar working example.
