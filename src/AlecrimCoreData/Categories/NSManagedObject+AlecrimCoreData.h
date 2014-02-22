//
//  NSManagedObject+AlecrimCoreData.h
//  Imagem
//
//  Created by Vanderlei Martinelli on 15/10/13.
//  Copyright (c) 2013 Alecrim. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (AlecrimCoreData)

// info
+ (NSString *)entityName;

// create
+ (instancetype)createInContext:(NSManagedObjectContext *)context;

// truncate
+ (void)truncateAllInContext:(NSManagedObjectContext *)context;

// find
+ (instancetype)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (instancetype)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;

+ (instancetype)findFirstWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (instancetype)findFirstWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;

+ (NSArray *)findAllInContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;

#if TARGET_OS_IPHONE
// fetch
+ (NSFetchedResultsController *)fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context;
+ (NSFetchedResultsController *)fetchAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context;
+ (NSFetchedResultsController *)fetchAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending groupBy:(NSString *)groupingKeyPath delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context;
#endif

// count
+ (NSUInteger)countOfEntitiesWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)localContext;
+ (NSUInteger)countForFetchRequest:(NSFetchRequest *)fetchRequest inContext:(NSManagedObjectContext *)localContext;

// aggegation
+ (id)aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

// request
+ (NSFetchRequest *)requestAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending fetchLimit:(NSUInteger)fetchLimit inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestAllWithPredicate:(NSPredicate *)predicate sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending fetchLimit:(NSUInteger)fetchLimit fetchOffset:(NSUInteger)fetchOffset fetchBatchSize:(NSUInteger)fetchBatchSize inContext:(NSManagedObjectContext *)context;

// delete
- (void)deleteInContext:(NSManagedObjectContext *)context;

//
- (id)inContext:(NSManagedObjectContext *)otherContext;

//
- (void)copyAttributesFromManagedObject:(NSManagedObject *)sourceManagedObject;


@end
