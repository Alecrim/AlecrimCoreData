//
//  VMCoreDataManager.m
//  Imagem
//
//  Created by Vanderlei Martinelli on 15/10/13.
//  Copyright (c) 2013 Alecrim. All rights reserved.
//

#import "VMCoreDataManager.h"

@interface VMCoreDataManager ()

@property (strong, nonatomic) NSString *storeName;
@property (strong, nonatomic) NSString *storeType;
@property (strong, nonatomic) NSString *configuration;

@property (assign, nonatomic, getter = isCloudEnabled) BOOL cloudEnabled;
@property (assign, nonatomic, getter = isCloudAvailable) BOOL cloudAvailable;

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSPersistentStore *persistentStore;

@property (strong, nonatomic, readwrite) NSManagedObjectContext *mainContext;
@property (strong, nonatomic, readwrite) NSManagedObjectContext *backgroundContext;

- (void)createManagedObjectContexts;
- (void)saveContext:(NSManagedObjectContext *)context synchronously:(BOOL)synchronously completionHandler:(VMCoreDataManagerCompletionHandler)completionHandler;
- (void)mergeChangesFromNotification:(NSNotification *)notification intoContext:(NSManagedObjectContext *)intoContext didImportUbiquitousContentChangesNotificationHandler:(BOOL)didImportUbiquitousContentChangesNotificationHandler;

- (NSManagedObjectModel *)defaultManagedObjectModel;
- (NSURL *)urlForStoreFileName:(NSString *)storeFileName;
- (void)createDirectoryForFileURL:(NSURL *)fileURL;
- (void)handleErrors:(NSError *)error;

- (void)contextWillSaveNotificationHandler:(NSNotification *)notification;
- (void)contextDidSaveNotificationHandler:(NSNotification *)notification;

- (void)persistentStoreCoordinatorStoresWillChangeNotificationHandler:(NSNotification *)notification;
- (void)persistentStoreCoordinatorStoresDidChangeNotificationHandler:(NSNotification *)notification;
- (void)persistentStoreDidImportUbiquitousContentChangesNotificationHandler:(NSNotification *)notification;

@end

@implementation VMCoreDataManager

#pragma mark - @synthesize

@dynamic currentContext;

#pragma mark - @synthesize methods

- (NSManagedObjectContext *)currentContext
{
    if (IsMainThread())
    {
        return self.mainContext;
    }
    else
    {
        return self.backgroundContext;
    }
}

#pragma mark - init and dealloc

- (id)initWithStoreName:(NSString *)storeName storeType:(NSString *)storeType configuration:(NSString *)configuration enableCloud:(BOOL)enableCloud
{
    self = [super init];
    if (self != nil)
    {
        self.storeName = storeName;
        self.storeType = storeType;
        self.configuration = configuration;
        self.cloudEnabled = (enableCloud && [storeType isEqualToString:NSSQLiteStoreType]);
        
        self.cloudAvailable = ([[NSFileManager defaultManager] ubiquityIdentityToken] != nil);
        
        //
        [self setup];
    }
    
    return self;
}

- (void)dealloc
{
    if ([self isCloudEnabled])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:self.persistentStoreCoordinator];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:self.persistentStoreCoordinator];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:self.persistentStoreCoordinator];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.backgroundContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:self.backgroundContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.mainContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:self.mainContext];

    self.backgroundContext = nil;
    self.mainContext = nil;
    
    self.persistentStore = nil;
    self.persistentStoreCoordinator = nil;
    self.managedObjectModel = nil;
    
    self.storeName = nil;
    self.storeType = nil;
    self.configuration = nil;
}

#pragma mark - public methods - save

- (void)saveWithBlock:(VMCoreDataManagerSaveContextBlock)block
{
    [self saveWithBlock:block completionHandler:nil];
}

- (void)saveWithBlock:(VMCoreDataManagerSaveContextBlock)block completionHandler:(VMCoreDataManagerCompletionHandler)completionHandler
{
    NSManagedObjectContext *localContext = self.backgroundContext;
    
    CreateWeakSelf();
    __typeof(localContext) __weak weakLocalContext = localContext;
    [localContext performBlock:^{
        
        CreateShadowStrongSelf();
        __typeof(weakLocalContext) __strong strongLocalContext = weakLocalContext;
        if (strongLocalContext == nil)
        {
            return;
        }
        
        //
        block(strongLocalContext);
        
        //
        [self saveContext:strongLocalContext synchronously:NO completionHandler:completionHandler];
        
    }];
}

- (void)saveWithBlockAndWait:(VMCoreDataManagerSaveContextBlock)block
{
    [self saveWithBlockAndWait:block completionHandler:nil];
}

- (void)saveWithBlockAndWait:(VMCoreDataManagerSaveContextBlock)block completionHandler:(VMCoreDataManagerCompletionHandler)completionHandler
{
    NSManagedObjectContext *localContext = self.backgroundContext;

    CreateWeakSelf();
    __typeof(localContext) __weak weakLocalContext = localContext;
    [localContext performBlockAndWait:^{
        
        CreateShadowStrongSelf();
        __typeof(weakLocalContext) __strong strongLocalContext = weakLocalContext;
        if (strongLocalContext == nil)
        {
            return;
        }
        
        //
        block(strongLocalContext);
        
        //
        [self saveContext:strongLocalContext synchronously:YES completionHandler:completionHandler];
        
    }];
}

#pragma mark - public methods - de-duplicate

- (void)handlePreSaveWithContext:(NSManagedObjectContext *)context
{
    // do nothing, to be overriden
}

- (void)deDuplicateInsertedObjects:(NSSet *)insertedObjects context:(NSManagedObjectContext *)context
{
    // do nothing, to be overriden
}

#pragma mark - private methods - setup

- (void)setup
{
    //
    self.managedObjectModel = [self defaultManagedObjectModel];
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    
    //
    NSURL *localStoreURL = nil;
    NSDictionary *options = nil;
    
    //
    if ([self.storeType isEqualToString:NSSQLiteStoreType])
    {
        NSString *storeFileName = [self.storeName stringByAppendingPathExtension:@"sqlite"];
        localStoreURL = [self urlForStoreFileName:storeFileName];
        [self createDirectoryForFileURL:localStoreURL];
    }
    
    //
    if ([self isCloudEnabled])
    {
        //
        options = @{
                    NSPersistentStoreUbiquitousContentNameKey: @"UbiquityStore",
                    NSPersistentStoreUbiquitousContentURLKey: @"Data/TransactionLogs",
                    NSMigratePersistentStoresAutomaticallyOption: @YES,
                    NSInferMappingModelAutomaticallyOption: @YES
                    };
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(persistentStoreCoordinatorStoresWillChangeNotificationHandler:)
                                                     name:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                                   object:self.persistentStoreCoordinator];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(persistentStoreCoordinatorStoresDidChangeNotificationHandler:)
                                                     name:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                                   object:self.persistentStoreCoordinator];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(persistentStoreDidImportUbiquitousContentChangesNotificationHandler:)
                                                     name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                   object:self.persistentStoreCoordinator];
    }
    else
    {
        options = @{
                    NSMigratePersistentStoresAutomaticallyOption: @YES,
                    NSInferMappingModelAutomaticallyOption: @YES
                    };
    }
    
    //
    NSError *error = nil;
    [self.persistentStoreCoordinator lock];
    self.persistentStore = [self.persistentStoreCoordinator addPersistentStoreWithType:self.storeType configuration:self.configuration URL:localStoreURL options:options error:&error];
    [self.persistentStoreCoordinator unlock];
    
    if (self.persistentStore == nil || error != nil)
    {
        [self handleErrors:error];
        abort(); // TODO: abort ?
    }
    
    //
    [self createManagedObjectContexts];
}

#pragma mark - private methods

- (void)createManagedObjectContexts
{
    // main context
    self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.mainContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [self.mainContext setUndoManager:nil];
    [self.mainContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextWillSaveNotificationHandler:)
                                                 name:NSManagedObjectContextWillSaveNotification
                                               object:self.mainContext];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextDidSaveNotificationHandler:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.mainContext];

    // background context
    self.backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [self.backgroundContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [self.backgroundContext setUndoManager:nil];
    [self.backgroundContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextWillSaveNotificationHandler:)
                                                 name:NSManagedObjectContextWillSaveNotification
                                               object:self.backgroundContext];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextDidSaveNotificationHandler:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.backgroundContext];
}

- (void)saveContext:(NSManagedObjectContext *)context synchronously:(BOOL)synchronously completionHandler:(VMCoreDataManagerCompletionHandler)completionHandler
{
    if ([context hasChanges])
    {
        __typeof(context) __weak weakContext = context;

        void (^saveBlock)() = ^{
            
            __typeof(weakContext) __strong strongContext = weakContext;
            if (strongContext == nil)
            {
                return;
            }

            //
            [self handlePreSaveWithContext:strongContext];

            //
            NSError *error = nil;
            BOOL saved = [strongContext save:&error];
            
            if (saved)
            {
                if (IsMainThread())
                {
                    ExecuteBlock(completionHandler, YES, nil);
                }
                else
                {
                    if (completionHandler != nil)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completionHandler(YES, nil);
                        });
                    }
                }
            }
            else
            {
                if (IsMainThread())
                {
                    ExecuteBlock(completionHandler, NO, error);
                }
                else
                {
                    if (completionHandler != nil)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completionHandler(NO, error);
                        });
                    }
                }
            }
            
        };
    
        if (synchronously)
        {
            [context performBlockAndWait:saveBlock];
        }
        else
        {
            [context performBlock:saveBlock];
        }
    }
    else
    {
        if (IsMainThread())
        {
            ExecuteBlock(completionHandler, YES, nil);
        }
        else
        {
            if (completionHandler != nil)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(YES, nil);
                });
            }
        }
    }
}

- (void)mergeChangesFromNotification:(NSNotification *)notification intoContext:(NSManagedObjectContext *)intoContext didImportUbiquitousContentChangesNotificationHandler:(BOOL)didImportUbiquitousContentChangesNotificationHandler
{
    CreateWeakSelf();
    __typeof(intoContext) __weak weakIntoContext = intoContext;
    [intoContext performBlock:^{
        
        CreateShadowStrongSelf();
        
        //
        __typeof(weakIntoContext) __strong strongIntoContext = weakIntoContext;
        if (strongIntoContext == nil)
        {
            return;
        }
        
        if (!didImportUbiquitousContentChangesNotificationHandler)
        {
            //
            // saving and merging the background context from stack #3 doesn't trigger the update in this case
            // http://floriankugler.com/blog/2013/4/29/concurrent-core-data-stack-performance-shootout
            // fix:
            NSArray *updatedObjects = [notification.userInfo valueForKey:NSUpdatedObjectsKey];
            for (id updatedObject in updatedObjects)
            {
                NSManagedObject *intoContextObject = nil;
                if ([updatedObject isKindOfClass:[NSManagedObject class]])
                {
                    intoContextObject = [intoContext objectWithID:[((NSManagedObject *)updatedObject) objectID]];
                }
                else if ([updatedObject isKindOfClass:[NSManagedObjectID class]])
                {
                    intoContextObject = [intoContext objectWithID:(NSManagedObjectID *)updatedObject];
                }
                
                if (intoContextObject != nil)
                {
                    [intoContextObject willAccessValueForKey:nil];
                }
            }
        }

        //
        [strongIntoContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

#pragma mark - private auxiliar methods

- (NSManagedObjectModel *)defaultManagedObjectModel
{
    return [NSManagedObjectModel mergedModelFromBundles:nil];
}

- (NSURL *)urlForStoreFileName:(NSString *)storeFileName
{
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    NSURL *applicationSupportDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *applicationStorageDirectory = [applicationSupportDirectory URLByAppendingPathComponent:applicationName isDirectory:YES];
    NSURL *storeFileDirectory = [applicationStorageDirectory URLByAppendingPathComponent:storeFileName isDirectory:NO];
    
    return storeFileDirectory;
}

- (void)createDirectoryForFileURL:(NSURL *)fileURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *directoryURL = [fileURL URLByDeletingLastPathComponent];
    
    NSError *createDirectoryError = nil;
    BOOL directoryWasCreated = [fileManager createDirectoryAtPath:[directoryURL path] withIntermediateDirectories:YES attributes:nil error:&createDirectoryError];
    
    if (!directoryWasCreated)
    {
        [self handleErrors:createDirectoryError];
    }
}

- (void)handleErrors:(NSError *)error
{
    DebugLog(@"%@", error);
}

#pragma mark - private methods - notifications

- (void)contextWillSaveNotificationHandler:(NSNotification *)notification
{
    NSManagedObjectContext *context = [notification object];
    NSSet *insertedObjects = [context insertedObjects];
    
    if ([insertedObjects count] > 0)
    {
        NSError *error = nil;
        BOOL success = [context obtainPermanentIDsForObjects:[insertedObjects allObjects] error:&error];
        if (!success)
        {
            [self handleErrors:error];
        }
    }
}

- (void)contextDidSaveNotificationHandler:(NSNotification *)notification
{
    NSManagedObjectContext *context = [notification object];
    
    if (context == self.mainContext)
    {
        [self mergeChangesFromNotification:notification intoContext:self.backgroundContext didImportUbiquitousContentChangesNotificationHandler:NO];
    }
    else if (context == self.backgroundContext)
    {
        [self mergeChangesFromNotification:notification intoContext:self.mainContext didImportUbiquitousContentChangesNotificationHandler:NO];
    }
}

- (void)persistentStoreCoordinatorStoresWillChangeNotificationHandler:(NSNotification *)notification
{
    DebugLog(@"%@", notification);

    //
    [self saveContext:self.mainContext synchronously:YES completionHandler:nil];
    [self saveContext:self.backgroundContext synchronously:YES completionHandler:nil];
    
    //
    [self.mainContext reset];
    [self.backgroundContext reset];
    
    // TODO: reset user interface?
}

- (void)persistentStoreCoordinatorStoresDidChangeNotificationHandler:(NSNotification *)notification
{
    DebugLog(@"%@", notification);
    
    //
    [self saveContext:self.mainContext synchronously:YES completionHandler:nil];
    [self saveContext:self.backgroundContext synchronously:YES completionHandler:nil];
    
    // TODO: refresh user interface?
}

- (void)persistentStoreDidImportUbiquitousContentChangesNotificationHandler:(NSNotification *)notification
{
    DebugLog(@"%@", notification);
    
    if (IsMainThread())
    {
        [self mergeChangesFromNotification:notification intoContext:self.mainContext didImportUbiquitousContentChangesNotificationHandler:YES];
        [self mergeChangesFromNotification:notification intoContext:self.backgroundContext didImportUbiquitousContentChangesNotificationHandler:YES];
    }
    else
    {
        [self mergeChangesFromNotification:notification intoContext:self.backgroundContext didImportUbiquitousContentChangesNotificationHandler:YES];
        [self mergeChangesFromNotification:notification intoContext:self.mainContext didImportUbiquitousContentChangesNotificationHandler:YES];
    }
    
    //
    NSSet *insertedObjects = [notification.userInfo objectForKey:NSInsertedObjectsKey];
    if ([insertedObjects count] > 0)
    {
        CreateWeakSelf();
        [self saveWithBlock:^(NSManagedObjectContext *localContext) {
            CreateShadowStrongSelf();
            [self deDuplicateInsertedObjects:insertedObjects context:localContext];
        }];
    }
}

@end
