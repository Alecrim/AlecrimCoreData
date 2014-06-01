//
//  VMCoreDataManager.h
//  Imagem
//
//  Created by Vanderlei Martinelli on 15/10/13.
//  Copyright (c) 2013 Alecrim. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^VMCoreDataManagerSetupCompletionHandler)(BOOL success, NSError *error);
typedef void (^VMCoreDataManagerCompletionHandler)(BOOL success, NSError *error);

typedef void (^VMCoreDataManagerSaveContextBlock)(NSManagedObjectContext *localContext);

@interface VMCoreDataManager : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectContext *mainContext;
@property (strong, nonatomic, readonly) NSManagedObjectContext *backgroundContext;
@property (strong, nonatomic, readonly) NSManagedObjectContext *currentContext;

- (id)initWithStoreName:(NSString *)storeName storeType:(NSString *)storeType configuration:(NSString *)configuration enableCloud:(BOOL)enableCloud;

- (void)saveWithBlock:(VMCoreDataManagerSaveContextBlock)block;
- (void)saveWithBlock:(VMCoreDataManagerSaveContextBlock)block completionHandler:(VMCoreDataManagerCompletionHandler)completionHandler;
- (void)saveWithBlockAndWait:(VMCoreDataManagerSaveContextBlock)block;
- (void)saveWithBlockAndWait:(VMCoreDataManagerSaveContextBlock)block completionHandler:(VMCoreDataManagerCompletionHandler)completionHandler;

- (void)handlePreSaveWithContext:(NSManagedObjectContext *)context;
- (void)deDuplicateInsertedObjects:(NSSet *)insertedObjects context:(NSManagedObjectContext *)context;
- (void)reloadData;

@end
