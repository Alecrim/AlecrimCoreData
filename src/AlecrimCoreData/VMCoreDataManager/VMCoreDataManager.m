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
- (void)mergeChangesFromNotification:(NSNotification *)notification intoContext:(NSManagedObjectContext *)intoContext;

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

    //
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
    NSManagedObjectContext *localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [localContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [localContext setUndoManager:nil];
    [localContext setParentContext:self.mainContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextWillSaveNotificationHandler:) name:NSManagedObjectContextWillSaveNotification object:localContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotificationHandler:) name:NSManagedObjectContextDidSaveNotification object:localContext];

    @weakify(self);
    [localContext performBlock:^{
        @strongify(self);
        
        //
        block(localContext);
        
        //
        [self saveContext:localContext synchronously:NO completionHandler:^(BOOL success, NSError *error) {
            @strongify(self);
            
            //
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:localContext];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:localContext];
            
            ExecuteBlock(completionHandler, success, error);
        }];
        
    }];
}

- (void)saveWithBlockAndWait:(VMCoreDataManagerSaveContextBlock)block
{
    [self saveWithBlockAndWait:block completionHandler:nil];
}

- (void)saveWithBlockAndWait:(VMCoreDataManagerSaveContextBlock)block completionHandler:(VMCoreDataManagerCompletionHandler)completionHandler
{
    NSManagedObjectContext *localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [localContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [localContext setUndoManager:nil];
    [localContext setParentContext:self.mainContext];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextWillSaveNotificationHandler:) name:NSManagedObjectContextWillSaveNotification object:localContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSaveNotificationHandler:) name:NSManagedObjectContextDidSaveNotification object:localContext];

    @weakify(self);
    [localContext performBlockAndWait:^{
        @strongify(self);
        
        //
        block(localContext);
        
        //
        [self saveContext:localContext synchronously:YES completionHandler:^(BOOL success, NSError *error) {
            @strongify(self);
            
            //
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:localContext];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:localContext];
            
            ExecuteBlock(completionHandler, success, error);
        }];
        
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

- (void)reloadData
{
    // do nothing, to be overriden
}

#pragma mark - private methods - setup

- (void)setup
{
    //
    self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:self.storeName withExtension:@"momd"]];
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
    // background context
    self.backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [self.backgroundContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [self.backgroundContext setUndoManager:nil];
    [self.backgroundContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    
    // main context
    self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.mainContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    [self.mainContext setUndoManager:nil];
    [self.mainContext setParentContext:self.backgroundContext];
}

- (void)saveContext:(NSManagedObjectContext *)context synchronously:(BOOL)synchronously completionHandler:(VMCoreDataManagerCompletionHandler)completionHandler
{
    if ([context hasChanges])
    {
        void (^saveBlock)() = ^{
            
            //
            [self handlePreSaveWithContext:context];

            //
            NSError *error = nil;
            BOOL saved = [context save:&error];
            
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

- (void)mergeChangesFromNotification:(NSNotification *)notification intoContext:(NSManagedObjectContext *)intoContext
{
    [intoContext performBlockAndWait:^{
        [intoContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

#pragma mark - private auxiliar methods

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
    while ([context parentContext] != nil)
    {
        context = [context parentContext];
        [self saveContext:context synchronously:YES completionHandler:nil];
    }
}

- (void)persistentStoreCoordinatorStoresWillChangeNotificationHandler:(NSNotification *)notification
{
    DebugLog(@"%@", notification);

    //
    //[self saveContext:self.mainContext synchronously:YES completionHandler:nil];
    //[self saveContext:self.backgroundContext synchronously:YES completionHandler:nil];
    
    //
    [self.backgroundContext reset];
    [self.mainContext reset];
    
    // TODO: reset user interface?
}

- (void)persistentStoreCoordinatorStoresDidChangeNotificationHandler:(NSNotification *)notification
{
    DebugLog(@"%@", notification);
    
    //
    //[self saveContext:self.mainContext synchronously:YES completionHandler:nil];
    //[self saveContext:self.backgroundContext synchronously:YES completionHandler:nil];

    //
    [self.backgroundContext reset];
    [self.mainContext reset];
    
    //
    [self reloadData];

    // TODO: refresh user interface?
}

- (void)persistentStoreDidImportUbiquitousContentChangesNotificationHandler:(NSNotification *)notification
{
    DebugLog(@"%@", notification);
    
    [self mergeChangesFromNotification:notification intoContext:self.backgroundContext];
    [self mergeChangesFromNotification:notification intoContext:self.mainContext];

    NSSet *insertedObjects = [notification.userInfo objectForKey:NSInsertedObjectsKey];
    if ([insertedObjects count] > 0)
    {
        @weakify(self);
        [self saveWithBlock:^(NSManagedObjectContext *localContext) {
            @strongify(self);
            [self deDuplicateInsertedObjects:insertedObjects context:localContext];
        }];
    }
}

@end
